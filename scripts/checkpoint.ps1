# checkpoint.ps1
# Session state checkpoint - saves task state for compaction survival.
# Invoked by gate-system or manually before long pauses.
#
# Usage: powershell -File checkpoint.ps1 -TaskId "<id>" -Description "<desc>" [-Files "file1,file2"] [-NextAction "<action>"]
#
# Output:
#   Writes JSON state to gates/<taskId>/checkpoint-<timestamp>.json
#   Appends entry to memory/checkpoints/checkpoint_index.jsonl
#   This state can be restored by compaction-survival.js after session compaction

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskId,

    [Parameter(Mandatory=$true)]
    [string]$Description,

    [string]$Files = "",

    [string]$NextAction = "",

    [string]$ErrorContext = "",

    [int]$ProgressPercent = 50
)

$configDir = "$env:USERPROFILE\.config\opencode"
$gatesDir = "$configDir\gates"
$checkpointDir = "$configDir\memory\checkpoints"
$indexFile = Join-Path $checkpointDir "checkpoint_index.jsonl"
$logFile = Join-Path $configDir "memory\gate-system.log"

function Log-Checkpoint($msg) {
    $line = "[checkpoint] $(Get-Date -Format 'HH:mm:ss') $msg"
    try {
        Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    } catch {}
}

Log-Checkpoint "START taskId=$TaskId"

# Ensure dirs exist
if (-not (Test-Path $checkpointDir)) {
    New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null
}

# Build checkpoint object
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$fileName = "checkpoint-$TaskId-$timestamp.json"
$filePath = Join-Path $checkpointDir $fileName

$fileList = @()
if ($Files) {
    $fileList = $Files -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

# Read existing pending tasks and active agents from state.yaml if present
$stateFile = Join-Path $gatesDir "$TaskId\state.yaml"
$pendingTasks = @()
$activeAgents = @()
if (Test-Path $stateFile) {
    $stateContent = Get-Content $stateFile -Raw
    if ($stateContent -match "pending_tasks:\s*\[([^\]]*)\]") {
        $pendingTasks = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne "" }
    }
    if ($stateContent -match "active_agents:\s*\[([^\]]*)\]") {
        $activeAgents = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne "" }
    }
}

$checkpoint = @{
    type            = "checkpoint"
    task_id         = $TaskId
    description     = $Description
    timestamp       = (Get-Date).ToUniversalTime().ToString("o")
    progress_percent = $ProgressPercent
    project_path    = (Get-Location).Path
    strategy        = "incremental"
    files_modified  = $fileList
    pending_tasks   = $pendingTasks
    active_agents   = $activeAgents
    next_action     = $NextAction
    error_context   = $ErrorContext
} | ConvertTo-Json -Depth 5

# Write checkpoint file
try {
    Set-Content -Path $filePath -Value $checkpoint -Encoding UTF8
} catch {
    Log-Checkpoint "FAIL write $fileName : $($_.Exception.Message)"
    Write-Host "[checkpoint] ERROR: Could not write $filePath" -ForegroundColor Red
    exit 1
}

# Append to index
$indexEntry = @{
    type      = "checkpoint"
    task_id   = $TaskId
    file      = $fileName
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Compress

try {
    Add-Content -Path $indexFile -Value $indexEntry -ErrorAction SilentlyContinue
} catch {
    Log-Checkpoint "WARN index append failed: $($_.Exception.Message)"
}

Log-Checkpoint "WROTE $fileName (files=$($fileList.Count) progress=$ProgressPercent%)"

Write-Host "[checkpoint] Saved: $fileName" -ForegroundColor Green
Write-Host "  Task: $TaskId" -ForegroundColor Gray
Write-Host "  Progress: $ProgressPercent%" -ForegroundColor Gray
Write-Host "  Files: $($fileList.Count) modified" -ForegroundColor Gray
Write-Host "  Next: $NextAction" -ForegroundColor Gray
exit 0
