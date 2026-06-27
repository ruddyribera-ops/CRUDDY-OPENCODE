# system-dashboard.ps1
# Live operational dashboard for OpenCode system health
# Run: powershell scripts/system-dashboard.ps1
# No args = fast summary. -Watch = continuous monitoring.

param(
    [switch]$Detailed,
    [switch]$Watch,
    [int]$WatchInterval = 30
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"
$memoryDir = "$configDir\memory"
$gatesDir = "$configDir\gates"

function Get-LogHealth {
    param([string]$path, [string]$name)
    if (-not (Test-Path $path)) {
        return @{ Name = $name; Status = "FAIL"; Detail = "File not found" }
    }
    $size = (Get-Item $path).Length
    $lines = (Get-Content $path).Count
    $lastWrite = (Get-Item $path).LastWriteTime
    $ageMin = [math]::Round(((Get-Date) - $lastWrite).TotalMinutes, 0)
    $status = if ($ageMin -gt 60) { "WARN" } else { "PASS" }
    return @{ Name = $name; Status = $status; Detail = "$lines lines / $([math]::Round($size/1MB,2))MB / ${ageMin}m ago" }
}

# ── Metrics collector ─────────────────────────────────────────────
$metrics = @{ Pass = 0; Warn = 0; Fail = 0; Checks = @() }

function Add-Check {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $s = @{ Name = $Name; Status = $Status; Detail = $Detail }
    $script:metrics.Checks += $s
    switch ($Status) {
        "PASS" { $script:metrics.Pass++ }
        "WARN" { $script:metrics.Warn++ }
        "FAIL" { $script:metrics.Fail++ }
    }
}

function Show-Check {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "FAIL") { "Red" } else { "Yellow" }
    $label = "[$Status]".PadRight(7)
    if ($Detail) {
        Write-Host "  $label $Name" -ForegroundColor $color
        Write-Host "        $Detail" -ForegroundColor DarkGray
    } else {
        Write-Host "  $label $Name" -ForegroundColor $color
    }
}

# ═══════════════════════════════════════════════════════════════════
do {
    Clear-Host
    $script:metrics = @{ Pass = 0; Warn = 0; Fail = 0; Checks = @() }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $total = $metrics.Pass + $metrics.Warn + $metrics.Fail
    $pct = if ($total -gt 0) { [math]::Round(($metrics.Pass / $total) * 100, 1) } else { 100 }
    $overallColor = if ($pct -ge 90) { "Green" } elseif ($pct -ge 70) { "Yellow" } else { "Red" }

    # ══ HEADER ══════════════════════════════════════════════════════
    Write-Host ""
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host "       OPENCODE SYSTEM DASHBOARD  --  $timestamp" -ForegroundColor Cyan
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host ""

    # ══ SECTION 1: CORE MEMORY ══════════════════════════════════════
    Write-Host "  -- CORE MEMORY SYSTEM -----------------------------------" -ForegroundColor Cyan

    # auto-memory
    $amPath = "$memoryDir\auto-memory.log"
    $amOK = 0; $amFAIL = 0; $amRate = "N/A"
    if (Test-Path $amPath) {
        $amContent = Get-Content $amPath -Raw
        $amOK = ($amContent.Split("`n") | Where-Object { $_ -match "status=OK" }).Count
        $amFAIL = ($amContent.Split("`n") | Where-Object { $_ -match "status=FAILED" }).Count
        $totalAM = $amOK + $amFAIL
        if ($totalAM -gt 0) { $amRate = "$([math]::Round(($amOK/$totalAM)*100,1))%" }
    }
    $amStatus = if ($amFAIL -eq 0) { "PASS" } elseif ($amFAIL -lt 5) { "WARN" } else { "FAIL" }
    Add-Check "auto-memory" $amStatus "$amOK OK / $amFAIL FAIL / $amRate"
    Show-Check "auto-memory.log" $amStatus "$amOK OK / $amFAIL FAIL -- rate: $amRate"

    # session_events
    $evPath = "$memoryDir\session_events.jsonl"
    $evLines = (Get-Content $evPath | Measure-Object -Line).Lines
    $evMB = [math]::Round((Get-Item $evPath).Length/1MB, 2)
    $evStatus = if ($evLines -le 10000) { "PASS" } elseif ($evLines -le 15000) { "WARN" } else { "FAIL" }
    Add-Check "session_events" $evStatus "$evLines lines (10K threshold)"
    Show-Check "session_events.jsonl" $evStatus "$evLines lines / ${evMB}MB -- 10K threshold"

    # CASS index
    $cassPath = "$memoryDir\cass\index.jsonl"
    $cassLines = (Get-Content $cassPath | Measure-Object -Line).Lines
    $cassMB = [math]::Round((Get-Item $cassPath).Length/1MB, 2)
    $cassStatus = if ($cassLines -gt 1000) { "PASS" } elseif ($cassLines -gt 100) { "WARN" } else { "FAIL" }
    Add-Check "CASS index" $cassStatus "$cassLines entries"
    Show-Check "cass/index.jsonl" $cassStatus "$cassLines entries / ${cassMB}MB"

    # session_log
    $logPath = "$memoryDir\session_log.md"
    $logReal = 0
    if (Test-Path $logPath) {
        $logContent = Get-Content $logPath -Raw
        $logReal = ($logContent -split "`n" | Where-Object { $_ -match "coordinator|code-builder|bug-fixer|architecture|project-gen" }).Count
    }
    $logReal = 0
    if (Test-Path $logPath) {
        $logContent = Get-Content $logPath -Raw
        $logReal = ($logContent -split "`n" | Where-Object { $_ -match "main-coordinator|code-builder|bug-fixer|architecture|project-gen" }).Count
    }
    $logStatus = if ($logReal -gt 0) { "PASS" } else { "WARN" }
    Add-Check "session_log" $logStatus "$logReal real tasks"
    Show-Check "session_log.md" $logStatus "$logReal real tasks logged"

    Write-Host ""

    # ══ SECTION 2: HOOKS & PLUGINS ═════════════════════════════════
    Write-Host "  -- HOOKS & PLUGINS --------------------------------------" -ForegroundColor Cyan

    # Compaction hook
    $cpPath = "$memoryDir\compaction-survival.log"
    $cpFired = 0; $cpInit = 0
    if (Test-Path $cpPath) {
        $cpContent = Get-Content $cpPath -Raw
        # Match actual log line in compaction-survival.js: "experimental.session.compacting fired — injecting context"
        $cpFired = ($cpContent.Split("`n") | Where-Object { $_ -match "fired" }).Count
        $cpInit = ($cpContent.Split("`n") | Where-Object { $_ -match "Initialized" }).Count
    }
    $cpStatus = if ($cpFired -gt 0) { "PASS" } elseif ($cpInit -gt 0) { "WARN" } else { "FAIL" }
    Add-Check "compaction hook" $cpStatus "$cpFired fires / $cpInit inits"
    Show-Check "compaction-survival.js" $cpStatus "$cpFired hook fires / $cpInit plugin inits"

    # Hook errors
    $hookErrPath = "$configDir\hook-errors.log"
    $hookErrs = 0; $hookLast = "never"
    if (Test-Path $hookErrPath) {
        $hookContent = Get-Content $hookErrPath -Raw
        $hookErrs = ($hookContent.Split("`n") | Where-Object { $_ -match "auto-memory.*failed" }).Count
        $lastEntry = ($hookContent.Split("`n") | Where-Object { $_ -match "^\[\d{4}-\d{2}-\d{2}" } | Select-Object -Last 1)
        if ($lastEntry -match "^\[(\d{4}-\d{2}-\d{2})") { $hookLast = $matches[1] }
    }
    $hookStatus = if ($hookErrs -eq 0) { "PASS" } elseif ($hookErrs -lt 10) { "WARN" } else { "FAIL" }
    Add-Check "hook errors" $hookStatus "$hookErrs errors"
    Show-Check "hook-errors.log" $hookStatus "$hookErrs auto-memory errors / last: $hookLast"

    # memory-bridge init
    $mbMarker = "$gatesDir\.memory-bridge-load.txt"
    if (Test-Path $mbMarker) {
        $mbLoads = (Get-Content $mbMarker).Count
        Add-Check "memory-bridge loads" "PASS" "$mbLoads load events"
        Show-Check "memory-bridge.js init" "PASS" "$mbLoads load events recorded"
    } else {
        Add-Check "memory-bridge init" "WARN" "marker not yet created"
        Show-Check "memory-bridge.js init" "WARN" "not yet created (first run?)"
    }

    # gate-system init
    $gateMarker = "$gatesDir\.gate-system-init.marker"
    if (Test-Path $gateMarker) {
        Add-Check "gate-system init" "PASS"
        Show-Check "gate-system.js init" "PASS"
    } else {
        Add-Check "gate-system init" "WARN"
        Show-Check "gate-system.js init" "WARN"
    }

    Write-Host ""

    # ══ SECTION 3: TASK THROUGHPUT ═══════════════════════════════════
    Write-Host "  -- TASK THROUGHPUT --------------------------------------" -ForegroundColor Cyan

    # Task counter
    $counterPath = "$gatesDir\.task-counter.json"
    $taskCount = 0; $taskLast = "never"
    if (Test-Path $counterPath) {
        $counter = Get-Content $counterPath -Raw | ConvertFrom-Json
        $taskCount = $counter.count
        if ($counter.last) { $taskLast = $counter.last }
    }
    $taskStatus = if ($taskCount -gt 0) { "PASS" } else { "WARN" }
    Add-Check "task counter" $taskStatus "$taskCount tasks"
    Show-Check "Task counter" $taskStatus "$taskCount tasks / last: $taskLast"

    # Gate failures
    $gateLogPath = "$memoryDir\gate-system.log"
    $gateFails = 0
    if (Test-Path $gateLogPath) {
        $gateContent = Get-Content $gateLogPath -Raw
        $gateFails = ($gateContent.Split("`n") | Where-Object { $_ -match "FAILED" }).Count
    }
    $gateFailStatus = if ($gateFails -eq 0) { "PASS" } elseif ($gateFails -lt 5) { "WARN" } else { "FAIL" }
    Add-Check "gate failures" $gateFailStatus "$gateFails failures"
    Show-Check "gate-system failures" $gateFailStatus "$gateFails failures recorded"

    # Session events last hour
    if (Test-Path $evPath) {
        $evContent = Get-Content $evPath -Raw
        $lastHour = (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:")
        $recentEv = ($evContent.Split("`n") | Where-Object { $_ -match $lastHour }).Count
        $evFreqStatus = if ($recentEv -gt 10) { "PASS" } elseif ($recentEv -gt 0) { "WARN" } else { "INFO" }
        Add-Check "events/hour" $evFreqStatus "$recentEv events"
        Show-Check "Session events (last hour)" $evFreqStatus "$recentEv events"
    }

    Write-Host ""

    # ══ SECTION 4: MCP SERVERS ══════════════════════════════════════
    Write-Host "  -- MCP SERVERS ------------------------------------------" -ForegroundColor Cyan

    $ocfg = Get-Content "$configDir\opencode.json" -Raw | ConvertFrom-Json
    foreach ($mcpName in $ocfg.mcp.PSObject.Properties.Name) {
        $mcp = $ocfg.mcp.$mcpName
        $enabled = $mcp.enabled -eq $true
        $type = if ($mcp.type) { $mcp.type } else { "unknown" }
        $status = if ($enabled) { "PASS" } else { "WARN" }
        Add-Check "MCP: $mcpName" $status "$type"
        Show-Check "MCP: $mcpName" $status "type=$type"
    }

    Write-Host ""

    # ══ SECTION 5: AGENTS & SKILLS ══════════════════════════════════
    Write-Host "  -- AGENTS & SKILLS --------------------------------------" -ForegroundColor Cyan

    $agentCount = $ocfg.agent.PSObject.Properties.Count
    Add-Check "agents" "PASS" "$agentCount"
    $agentList = ($ocfg.agent.PSObject.Properties | ForEach-Object { $_.Name }) -join ", "
    Show-Check "Agents" "PASS" "$agentList"

    $skillDir = "$configDir\skills"
    $activeSkills = (Get-ChildItem $skillDir -Directory | Where-Object { $_.Name -ne ".archive" }).Count
    Add-Check "skills" "PASS" "$activeSkills active"
    Show-Check "Skills" "PASS" "$activeSkills active skills"

    $swarmPy = "$configDir\lib\swarm.py"
    $crewFact = "$configDir\lib\agents\crew_factory.py"
    $swarmOK = (Test-Path $swarmPy) -and (Test-Path $crewFact)
    $swarmStatus = if ($swarmOK) { "PASS" } else { "FAIL" }
    Add-Check "swarm" $swarmStatus
    Show-Check "Swarm (CrewAI)" $swarmStatus "crew_factory: $(if(Test-Path $crewFact){'YES'}else{'MISSING'}) swarm.py: $(if(Test-Path $swarmPy){'YES'}else{'MISSING'})"

    Write-Host ""

    # ══ SECTION 5B: DNA / GENE EVOLUTION ══════════════════════════
    Write-Host "  -- DNA / GENE EVOLUTION -------------------------------" -ForegroundColor Cyan

    # Gene count and pending
    $dnaPath = "$configDir\skills\DNA.yaml"
    $totalGenes = 0; $autoGenes = 0; $pendingGenes = 0; $approvedGenes = 0; $rejectedGenes = 0
    if (Test-Path $dnaPath) {
        $dnaContent = Get-Content $dnaPath -Raw
        $totalGenes = ($dnaContent.Split("`n") | Where-Object { $_ -match "^\s+- id:\s+\w+" }).Count
$autoGenes      = ([regex]::Matches($dnaContent, '(?m)^\s{2,4}auto_generated:\s*true\s*$')).Count
        $approvedGenes = ([regex]::Matches($dnaContent, '(?m)^\s{2,4}auto_approved:\s*true\s*$')).Count
        $rejectedGenes = ([regex]::Matches($dnaContent, '(?m)^\s{2,4}auto_rejected:\s*true\s*$')).Count
        $pendingGenes = $autoGenes - $approvedGenes - $rejectedGenes
    }
    $geneStatus = if ($pendingGenes -eq 0) { "PASS" } else { "WARN" }
    Add-Check "DNA genes" $geneStatus "total=$totalGenes / auto=$autoGenes / pending=$pendingGenes"
    Show-Check "DNA.yaml" $geneStatus "total=$totalGenes genes / auto=$autoGenes / pending=$pendingGenes"

    # Pattern maturity
    $pmPath = "$memoryDir\outcomes\pattern_maturity.yaml"
    $blockedCount = 0; $provenCount = 0; $candidateCount = 0
    if (Test-Path $pmPath) {
        $pmContent = Get-Content $pmPath -Raw
        $blockedCount = ($pmContent.Split("`n") | Where-Object { $_ -match "^\s+db-migration:" }).Count
        $provenCount = ($pmContent.Split("`n") | Where-Object { $_ -match "maturity:\s*proven" }).Count
        $candidateCount = ($pmContent.Split("`n") | Where-Object { $_ -match "maturity:\s*candidate" }).Count
    }
    $pmStatus = if ($blockedCount -gt 0) { "WARN" } else { "PASS" }
    Add-Check "pattern_maturity" $pmStatus "blocked=$blockedCount / proven=$provenCount / candidate=$candidateCount"
    Show-Check "Pattern maturity" $pmStatus "blocked=$blockedCount / proven=$provenCount / candidate=$candidateCount"

    # Outcome tracking health
    $pjPath = "$memoryDir\outcomes\patterns.jsonl"
    $pjCount = 0; $pjMB = "0"
    if (Test-Path $pjPath) {
        $pjCount = (Get-Content $pjPath | Measure-Object -Line).Lines
        $pjMB = [math]::Round((Get-Item $pjPath).Length/1MB, 2)
    }
    $pjStatus = if ($pjCount -eq 0) { "FAIL" } elseif ($pjCount -lt 10) { "WARN" } else { "PASS" }
    Add-Check "outcome tracking" $pjStatus "$pjCount entries"
    Show-Check "patterns.jsonl" $pjStatus "$pjCount entries recorded"

    # Retro-analyze firing status — use in-script count derived from DNA.yaml (lines 256-264)
    $pendingFromScript = $pendingGenes
    $raStatus = if ($pendingFromScript -eq 0) { "PASS" } else { "WARN" }
    Add-Check "retro-analyze" $raStatus "$pendingFromScript pending genes"
    Show-Check "Pending genes" $raStatus "$pendingFromScript awaiting evolution review"

    Write-Host ""

    # ══ FAILURES DETAIL ═════════════════════════════════════════════
    $problems = $metrics.Checks | Where-Object { $_.Status -ne "PASS" } | Select-Object -First 10
    if ($problems.Count -gt 0) {
        Write-Host "  -- FAILURES & WARNINGS ----------------------------------" -ForegroundColor $(if($metrics.Fail-gt 0){"Red"}else{"Yellow"})
        foreach ($p in $problems) {
            $color = if ($p.Status -eq "FAIL") { "Red" } else { "Yellow" }
            $label = "[$($p.Status)]".PadRight(7)
            Write-Host "  $label $($p.Name)" -ForegroundColor $color
            if ($p.Detail) { Write-Host "        $($p.Detail)" -ForegroundColor DarkGray }
        }
        Write-Host ""
    }

    # ══ DNA-SPECIFIC WARNINGS ═══════════════════════════════════════
    if ($pendingGenes -gt 0) {
        Write-Host "  -- DNA EVOLUTION ACTION NEEDED ------------------------" -ForegroundColor Yellow
        Write-Host "    $pendingGenes gene(s) pending review — run evolution-agent" -ForegroundColor Yellow
        Write-Host ""
    }
    if ($blockedCount -gt 0) {
        Write-Host "    $blockedCount blocked pattern(s) in routing — see pattern_maturity.yaml" -ForegroundColor Yellow
        Write-Host ""
    }

    # ══ SUMMARY ═════════════════════════════════════════════════════
    Write-Host "  =========================================================" -ForegroundColor DarkGray
    Write-Host "   SUMMARY  --  PASS: $($metrics.Pass)  WARN: $($metrics.Warn)  FAIL: $($metrics.Fail)" -ForegroundColor White
    Write-Host "   Health Score: $pct% -- " -NoNewline -ForegroundColor $overallColor
    if ($metrics.Fail -gt 0) {
        Write-Host " ATTENTION NEEDED" -ForegroundColor Red
    } elseif ($metrics.Warn -gt 0) {
        Write-Host " MINOR ISSUES" -ForegroundColor Yellow
    } else {
        Write-Host " ALL SYSTEMS NOMINAL" -ForegroundColor Green
    }
    Write-Host "  =========================================================" -ForegroundColor DarkGray
    Write-Host ""

    if ($Watch) {
        Write-Host "   Refreshing in $WatchInterval seconds... (Ctrl+C to stop)" -ForegroundColor DarkGray
        Start-Sleep $WatchInterval
    }
} while ($Watch)