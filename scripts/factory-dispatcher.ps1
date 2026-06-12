# factory-dispatcher.ps1
# Sprint1G — Layer 2 Factory Pipeline
# Auto-chains agents: AM -> PM -> Architect -> Tech Lead -> Builder -> QA -> Delivery
#
# How it works:
#   1. Reads queue file: memory/factory/pipeline-queue.jsonl
#   2. For each queued dispatch, calls OpenCode HTTP API
#   3. POST /session (create) -> POST /session/:id/message (run agent)
#   4. Saves agent output to result file
#   5. Enqueues next stage per handoff rules in AGENTS.md
#
# Usage:
#   # Start the dispatcher (runs in foreground loop)
#   pwsh -File scripts/factory-dispatcher.ps1 -Watch
#
#   # Enqueue a new project
#   pwsh -File scripts/factory-dispatcher.ps1 -EnqueueProject "Build a todo app"
#
#   # Process queue once and exit (no loop)
#   pwsh -File scripts/factory-dispatcher.ps1 -Once
#
#   # Start the OpenCode server (required)
#   pwsh -File scripts/factory-dispatcher.ps1 -StartServer

[CmdletBinding()]
param(
    [switch]$Watch,
    [switch]$Once,
    [switch]$StartServer,
    [switch]$StopServer,
    [switch]$Status,
    [string]$EnqueueProject,
    [string]$ProjectId,
    [int]$ServerPort = 4096,
    [int]$PollSeconds = 3
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ── Paths ──────────────────────────────────────────────────────
$ConfigRoot = $env:OPENCODE_CONFIG_HOME
if (-not $ConfigRoot) {
    $ConfigRoot = Join-Path $env:USERPROFILE ".config\opencode"
}
$MemoryDir     = Join-Path $ConfigRoot "memory"
$FactoryDir    = Join-Path $MemoryDir "factory"
$QueueFile     = Join-Path $FactoryDir "pipeline-queue.jsonl"
$LogFile       = Join-Path $FactoryDir "dispatcher.log"
$StateFile     = Join-Path $FactoryDir "dispatcher-state.json"
$ServerPidFile = Join-Path $FactoryDir "server.pid"

# Standard handoff chain — matches AGENTS.md
$HandoffChain = @{
    "am"         = "pm"
    "pm"         = "architect"
    "architect"  = "tech-lead"
    "tech-lead"  = "builder"
    "builder"    = "qa"
    "qa"         = "delivery"
    "delivery"   = $null  # terminal
}

$AgentMap = @{
    "am"        = "account-manager"
    "pm"        = "project-manager"
    "architect" = "solutions-architect"
    "tech-lead" = "tech-lead"
    "builder"   = "code-builder"
    "qa"        = "qa-engineer"
    "delivery"  = "delivery-engineer"
}

# ── Helpers ───────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')] [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    if ($Level -eq "ERROR") {
        Write-Host $line -ForegroundColor Red
    } elseif ($Level -eq "WARN") {
        Write-Host $line -ForegroundColor Yellow
    } elseif ($Level -eq "STAGE") {
        Write-Host $line -ForegroundColor Cyan
    } else {
        Write-Host $line
    }
}

function Ensure-Dirs {
    @($MemoryDir, $FactoryDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
}

# ── Server management ─────────────────────────────────────────
function Get-ServerRunning {
    try {
        $r = Invoke-RestMethod -Uri "http://127.0.0.1:$ServerPort/global/health" -TimeoutSec 3
        return $r.healthy
    } catch {
        return $false
    }
}

function Find-OpenCode {
    $candidates = @(
        "opencode.cmd",
        "opencode.exe",
        "opencode.ps1",
        (Join-Path $env:APPDATA "npm\opencode.cmd"),
        (Join-Path $env:APPDATA "npm\opencode.exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return (Resolve-Path $c).Path }
    }
    # Fallback: try via cmd
    return "cmd.exe"
}

function Start-Server {
    if (Get-ServerRunning) {
        Write-Log "OpenCode server already running on port $ServerPort"
        return
    }
    Write-Log "Starting OpenCode server on port $ServerPort..."
    $opencodeExe = Find-OpenCode
    Write-Log "Using executable: $opencodeExe"

    if ($opencodeExe -like "*.ps1") {
        $proc = Start-Process -FilePath "powershell" `
            -ArgumentList "-NoProfile", "-File", "`"$opencodeExe`"", "serve", "--port", "$ServerPort", "--hostname", "127.0.0.1" `
            -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $FactoryDir "server-stdout.log") `
            -RedirectStandardError (Join-Path $FactoryDir "server-stderr.log") `
            -PassThru
    } else {
        $proc = Start-Process -FilePath $opencodeExe `
            -ArgumentList "serve", "--port", "$ServerPort", "--hostname", "127.0.0.1" `
            -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $FactoryDir "server-stdout.log") `
            -RedirectStandardError (Join-Path $FactoryDir "server-stderr.log") `
            -PassThru
    }
    $proc.Id | Out-File -FilePath $ServerPidFile -Encoding ascii
    Write-Log "Server PID $($proc.Id) started"

    # Wait for server to be ready
    $waited = 0
    while (-not (Get-ServerRunning) -and $waited -lt 30) {
        Start-Sleep -Seconds 1
        $waited++
    }
    if (Get-ServerRunning) {
        Write-Log "Server is healthy"
    } else {
        Write-Log "Server failed to start within 30 seconds" "ERROR"
        throw "Server start timeout"
    }
}

function Stop-Server {
    if (Test-Path $ServerPidFile) {
        $pid = Get-Content $ServerPidFile
        Get-Process -Id $pid -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item $ServerPidFile -Force -ErrorAction SilentlyContinue
        Write-Log "Server stopped (PID $pid)"
    } else {
        Write-Log "No server PID file found" "WARN"
    }
}

# ── Queue management ─────────────────────────────────────────
function Read-Queue {
    if (-not (Test-Path $QueueFile)) { return @() }
    Get-Content $QueueFile | Where-Object { $_.Trim() } | ForEach-Object {
        try {
            $_ | ConvertFrom-Json
        } catch {
            Write-Log "Skipping malformed queue line: $_" "WARN"
        }
    }
}

function Write-Queue {
    param($Item)
    $line = $Item | ConvertTo-Json -Compress
    Add-Content -Path $QueueFile -Value $line
    Write-Log "Enqueued: $($Item.id) stage=$($Item.stage)"
}

function Remove-QueueItem {
    param([string]$Id)
    $lines = Get-Content $QueueFile | Where-Object { $_.Trim() -ne "" }
    $kept = $lines | Where-Object {
        try {
            $obj = $_ | ConvertFrom-Json
            $obj.id -ne $Id
        } catch { $true }
    }
    $kept | Out-File -FilePath $QueueFile -Encoding ascii
}

# ── Agent execution ─────────────────────────────────────────
function Invoke-Agent {
    param(
        [string]$AgentName,
        [string]$Prompt,
        [string]$Workdir
    )
    Write-Log "Spawning agent '$AgentName'" "STAGE"

    # Create session
    $sessionBody = @{ title = "pipeline-$AgentName-$(Get-Date -Format 'HHmmss')" } | ConvertTo-Json
    $session = Invoke-RestMethod -Uri "http://127.0.0.1:$ServerPort/session" `
        -Method Post -Body $sessionBody -ContentType "application/json"
    $sessionId = $session.id
    Write-Log "Session $sessionId created"

    # Build message body
    $msgBody = @{
        agent = $AgentName
        parts = @(@{ type = "text"; text = $Prompt })
    } | ConvertTo-Json -Depth 10

    # Send message and wait
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:$ServerPort/session/$sessionId/message" `
        -Method Post -Body $msgBody -ContentType "application/json" `
        -TimeoutSec 600

    Write-Log "Agent '$AgentName' completed"

    # Extract text content
    $text = ($response.parts | Where-Object { $_.type -eq "text" } | ForEach-Object { $_.text }) -join "`n`n"

    return @{
        sessionId = $sessionId
        text      = $text
        parts     = $response.parts
    }
}

# ── Stage processing ─────────────────────────────────────────
function Process-Item {
    param($Item)
    $itemId = $Item.id
    $stage = $Item.stage
    $agentName = $AgentMap[$stage]

    if (-not $agentName) {
        Write-Log "Unknown stage '$stage' for item $itemId" "ERROR"
        Remove-QueueItem -Id $itemId
        return
    }

    $projectDir = Join-Path (Join-Path $FactoryDir "projects") $Item.projectId
    if (-not (Test-Path $projectDir)) {
        New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
    }

    # Checkpoint: skip if result already exists
    $resultFile = Join-Path $projectDir "$stage-result.md"
    if (Test-Path $resultFile) {
        Write-Log "Stage '$stage' already done (checkpoint found). Skipping." "WARN"
        Remove-QueueItem -Id $itemId
        # Still enqueue next stage
        $nextStage = $HandoffChain[$stage]
        if ($nextStage) {
            $nextAgent = $AgentMap[$nextStage]
            $nextItem = @{
                id        = [guid]::NewGuid().ToString()
                projectId = $Item.projectId
                stage     = $nextStage
                prompt    = "Previous stage ($agentName) already completed. Read the project context at: $projectDir\context.md`n`nYour job as $nextAgent`: continue the pipeline."
                workdir   = $Item.workdir
                enqueuedAt = (Get-Date).ToString("o")
            }
            Write-Queue $nextItem
        }
        return
    }

    # Build prompt
    $contextFile = Join-Path $projectDir "context.md"
    $inputPrompt = $Item.prompt
    if (Test-Path $contextFile) {
        $prior = Get-Content $contextFile -Raw
        $inputPrompt = $prior + "`n`n-- New task for you ($agentName) --`n" + $Item.prompt
    }

    # Run agent
    try {
        Write-Log "Running agent '$agentName' (may take several minutes)..." "STAGE"
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $result = Invoke-Agent -AgentName $agentName -Prompt $inputPrompt -Workdir $Item.workdir
        $sw.Stop()

        # H3: Deadlock guard — if agent returned but no checkpoint written, HALT pipeline
        if (-not (Test-Path $resultFile) -and $sw.Elapsed.TotalMinutes -gt 3) {
            Write-Log "DEADLOCK: '$stage' ran for $([int]$sw.Elapsed.TotalMinutes)m but produced no checkpoint. Halting pipeline." "ERROR"
            $deadlockFile = Join-Path $projectDir "DEADLOCK-$stage.flag"
            "Stage $stage deadlocked at $(Get-Date -Format 's') after $($sw.Elapsed.TotalMinutes)m" | Out-File -FilePath $deadlockFile -Encoding utf8
            Remove-QueueItem -Id $itemId
            return
        }
    } catch {
        Write-Log "Agent '$agentName' failed: $_" "ERROR"
        # H4: Max retry count — track failures, remove after 3
        $retryCount = [int]($Item.retryCount)
        if ($retryCount -ge 3) {
            Write-Log "Item $itemId exceeded max retries (3). Removing from queue." "ERROR"
            Remove-QueueItem -Id $itemId
            $failedFile = Join-Path $projectDir "FAILED-$stage.flag"
            "Stage $stage failed after 3 retries at $(Get-Date -Format 's'): $_" | Out-File -FilePath $failedFile -Encoding utf8
            return
        }
        # Re-enqueue with incremented retry count
        $retryItem = @{
            id        = $itemId
            projectId = $Item.projectId
            stage     = $stage
            prompt    = $Item.prompt
            workdir   = $Item.workdir
            retryCount = $retryCount + 1
            enqueuedAt = (Get-Date).ToString("o")
        }
        Remove-QueueItem -Id $itemId
        Write-Queue $retryItem
        Write-Log "Re-enqueued $itemId (retry $($retryCount + 1)/3)"
        return
    }

    # Save result
    $result.text | Out-File -FilePath $resultFile -Encoding utf8
    Write-Log "Result saved: $resultFile" "STAGE"

    # Update context for next stage
    Add-Content -Path $contextFile -Value "`n`n## Stage: $agentName (completed $(Get-Date -Format 's')))`n`n$($result.text)"

    # Enqueue next stage
    $nextStage = $HandoffChain[$stage]
    if ($nextStage) {
        $nextAgent = $AgentMap[$nextStage]
        $nextItem = @{
            id        = [guid]::NewGuid().ToString()
            projectId = $Item.projectId
            stage     = $nextStage
            prompt    = "Previous stage ($agentName) completed. Read project context at: $contextFile`n`nYour job as $nextAgent`: continue the pipeline. Produce your deliverable."
            workdir   = $Item.workdir
            enqueuedAt = (Get-Date).ToString("o")
        }
        Write-Queue $nextItem
        Write-Log "Next stage enqueued: $nextStage (agent=$nextAgent)" "STAGE"
    } else {
        Write-Log "Pipeline complete for project $($Item.projectId)" "STAGE"
        $doneFile = Join-Path $projectDir "DONE.flag"
        "completed $(Get-Date -Format 's')" | Out-File -FilePath $doneFile
    }

    # Remove this item from queue
    Remove-QueueItem -Id $itemId
}

# ── Enqueue helper ───────────────────────────────────────────
function New-Project {
    param([string]$Brief)
    $projectId = if ($ProjectId) { $ProjectId } else { [guid]::NewGuid().ToString().Substring(0, 8) }
    $projectDir = Join-Path (Join-Path $FactoryDir "projects") $projectId
    New-Item -ItemType Directory -Path $projectDir -Force | Out-Null

    # Initial brief
    $briefFile = Join-Path $projectDir "brief.md"
    @"
# Project Brief

$Brief

Enqueued: $(Get-Date -Format 's')
ProjectId: $projectId
"@ | Out-File -FilePath $briefFile -Encoding utf8

    # Seed context
    "# Project $projectId`n`n## Brief`n`n$Brief" | Out-File -FilePath (Join-Path $projectDir "context.md") -Encoding utf8

    # Enqueue AM as first stage
    $firstItem = @{
        id        = [guid]::NewGuid().ToString()
        projectId = $projectId
        stage     = "am"
        prompt    = "New project brief is ready at: $briefFile`n`nRead the brief, then write a one-page project brief covering: problem, target user, success criteria, scope, timeline. Save your brief to: $projectDir\am-brief.md`n`nWhen done, summarize what you produced in 3-4 lines for the project-manager."
        workdir   = $projectDir
        enqueuedAt = (Get-Date).ToString("o")
    }
    Write-Queue $firstItem

    Write-Log "Project $projectId enqueued. Brief: $briefFile"
    Write-Log "Watch progress: Get-ChildItem '$projectDir'"
}

# ── Status ───────────────────────────────────────────────────
function Show-Status {
    Write-Host "=== Factory Dispatcher Status ===" -ForegroundColor Cyan
    Write-Host "Config: $ConfigRoot"
    Write-Host "Queue:  $QueueFile"
    Write-Host "Log:    $LogFile"
    Write-Host ""

    $serverOk = Get-ServerRunning
    if ($serverOk) {
        Write-Host "Server: RUNNING (port $ServerPort)" -ForegroundColor Green
    } else {
        Write-Host "Server: STOPPED" -ForegroundColor Red
    }

    $queue = Read-Queue
    Write-Host ""
    Write-Host "Queue items: $($queue.Count)"
    foreach ($item in $queue) {
        Write-Host "  - $($item.id.Substring(0, 8)) project=$($item.projectId) stage=$($item.stage)"
    }

    $projectsDir = Join-Path $FactoryDir "projects"
    if (Test-Path $projectsDir) {
        $projects = Get-ChildItem $projectsDir -Directory
        Write-Host ""
        Write-Host "Active projects: $($projects.Count)"
        foreach ($p in $projects) {
            $done = Test-Path (Join-Path $p.FullName "DONE.flag")
            $stages = (Get-ChildItem $p.FullName -Filter "*-result.md" -ErrorAction SilentlyContinue).Count
            $status = if ($done) { "[DONE]" } else { "[$stages/7 stages]" }
            Write-Host "  $($p.Name) $status"
        }
    }
}

# ── Main ─────────────────────────────────────────────────────
Ensure-Dirs

if ($StopServer) { Stop-Server; exit 0 }
if ($Status)     { Show-Status; exit 0 }
if ($StartServer) { Start-Server; exit 0 }
if ($EnqueueProject) { New-Project -Brief $EnqueueProject; exit 0 }

# Auto-start server if not running
if (-not (Get-ServerRunning)) {
    Start-Server
}

if ($Once) {
    Write-Log "Processing queue once"
    $queue = Read-Queue
    foreach ($item in $queue) {
        Process-Item $item
    }
    exit 0
}

if ($Watch) {
    Write-Log "Watching queue (poll every ${PollSeconds}s). Ctrl+C to stop."
    while ($true) {
        $queue = Read-Queue
        foreach ($item in $queue) {
            Process-Item $item
        }
        Start-Sleep -Seconds $PollSeconds
    }
}

# Default: show status if no action
Show-Status
