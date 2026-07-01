# t2-complete.ps1
# T2 (Task Complete) Protocol - Single-call wrapper
# Replaces the need for coordinator to remember 8+ manual steps.
#
# Usage:
#   powershell scripts/t2-complete.ps1 -TaskName "Fix bug in login" -Agent "bug-fixer"
#   powershell scripts/t2-complete.ps1 -TaskName "Add OAuth" -Agent "code-builder" -Result "Done" -Tokens 1500
#
# This is what the coordinator MUST call after every task completes.
# It runs the full T2 protocol: append-session-log, update-session-yaml, track-tokens,
# auto-memory flush, stamp-sprint, and graph write (fire-and-forget).

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,

    [string]$Agent = "main-coordinator",

    [string]$Result = "Done",

    [int]$Tokens = 0,

    [string]$TaskDescription = "",

    [string]$Files = "[]",

    [switch]$NoSprintStamp
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"
$memoryDir = "$configDir\memory"
$sessionLog = "$memoryDir\session_log.md"
$yamlPath = "$memoryDir\session.yaml"
$scriptsDir = "$configDir\scripts"

# Regex patterns (extracted to variables to avoid PS5.1 tokenizer mis-parsing [ as type annotation)
$sessionNamePattern = 'session_name:\s*"([^"]+)"'

# Truncate task name for table fit
$shortName = if ($TaskName.Length -gt 80) { $TaskName.Substring(0, 77) + "..." } else { $TaskName }
$tokensEst = if ($Tokens -gt 0) { "~$Tokens" } else { "~500" }
$description = if ($TaskDescription) { $TaskDescription } else { $TaskName }

$results = @()
$failed = @()

# ── 1. Append to session_log.md (with real task name) ──
try {
    & "$scriptsDir\append-session-log.ps1" -TaskName $shortName -Agent $Agent -Result $Result -TokensEst $tokensEst -SessionLogPath $sessionLog 2>$null | Out-Null
    $results += "session_log"
} catch {
    $failed += "session_log: $($_.Exception.Message)"
}

# ── 2. Update session.yaml tasks (track in session state) ──
$updateScript = "$scriptsDir\update-session-yaml.ps1"
if (Test-Path $updateScript) {
    try {
        & $updateScript -Action "add-task" -TaskDescription $description -Agent $Agent -Result $Result -Files $Files 2>$null | Out-Null
        $results += "session_yaml"
    } catch {
        $failed += "session_yaml: $($_.Exception.Message)"
    }
}

# ── 3. Track tokens (C4) ──
if ($Tokens -gt 0) {
    $tokenScript = "$scriptsDir\track-tokens.ps1"
    if (Test-Path $tokenScript) {
        try {
            & $tokenScript -Action "record" -Agent $Agent -Tokens $Tokens 2>$null | Out-Null
            $results += "tokens"
        } catch {
            $failed += "tokens: $($_.Exception.Message)"
        }
    }
}

# ── 4. Stamp sprint (C3) ──
if (-not $NoSprintStamp) {
    $stampScript = "$scriptsDir\stamp-sprint.ps1"
    if (Test-Path $stampScript) {
        try {
            & $stampScript -TaskDescription $description -SprintPath "$memoryDir\current_sprint.md" 2>$null | Out-Null
            $results += "sprint_stamp"
        } catch {
            $failed += "sprint_stamp: $($_.Exception.Message)"
        }
    }
}

# ── 5. CRITICAL: auto-memory flush with REAL task name ──
# This is the fix for the placeholder problem. Instead of waiting for
# session.idle to log "idle:untitled", we explicitly flush with the real name.
$autoMemScript = "$scriptsDir\auto-memory.ps1"
if (Test-Path $autoMemScript) {
    try {
        & $autoMemScript -TaskName $shortName -Agent $Agent -Result $Result -TokensEst $tokensEst 2>$null | Out-Null
        $results += "auto_memory"
    } catch {
        $failed += "auto_memory: $($_.Exception.Message)"
    }
}

# ── 6b. OUTCOME RECORDING ─ track task outcome to patterns.jsonl ──
# Also tracks gene activations for gene_fitness.jsonl (DNA gene fitness scoring)
$taskTypeMap = @{
    "code-builder"        = "implementation"
    "bug-fixer"           = "bug-fix"
    "code-analyzer"       = "analysis"
    "architecture-advisor" = "architecture"
    "code-explainer"      = "explanation"
    "project-generator"   = "project-gen"
    "evolution-agent"     = "evolution"
    "skill-manager"       = "skill-mgmt"
    "standup-summary"     = "standup"
    "code-reviewer"       = "review"
    "main-coordinator"    = "coordination"
}
$taskType = if ($taskTypeMap.ContainsKey($Agent)) { $taskTypeMap[$Agent] } else { "general" }
$isSuccess = $Result -eq "Done" -or $Result -eq "done" -or $Result -eq "PASS"
$filesTouched = 0
try {
    if ($Files -and $Files -ne "[]") {
        $fa = $Files | ConvertFrom-Json
        $filesTouched = if ($fa -is [System.Array]) { $fa.Count } else { 1 }
    }
} catch { $filesTouched = 0 }

$outcomeScript = "$scriptsDir\outcome-record.ps1"
if (Test-Path $outcomeScript) {
    try {
        & $outcomeScript -TaskType $taskType -FilesTouched $filesTouched -Errors 0 -RetryCount 0 -StrategyUsed "t2-protocol" -Agent $Agent -Success $(if($isSuccess){1}else{0}) 2>$null | Out-Null
        $results += "outcome_record"
    } catch {
        # outcome-record.ps1 is best-effort; failure must not break T2
        $failed += "outcome_record: $($_.Exception.Message)"
    }
}

# ── 6c. GENE FITNESS TRACKING ───────────────────────────────
# Record gene activations for DNA gene_fitness.jsonl
# Gene activation format: {gene_id, ts, activations, successes, cycles_since_seen}
$fitnessFile = "$memoryDir\outcomes\gene_fitness.jsonl"
if (Test-Path $fitnessFile) {
    try {
        $fitnessEntry = @{
            gene_id = "TASK-$taskType"
            ts = (Get-Date).ToUniversalTime().ToString("o")
            activations = 1
            successes = if ($isSuccess) { 1 } else { 0 }
            cycles_since_seen = 0
            agent = $Agent
            task_name = $shortName
        }
        $fitnessLine = $fitnessEntry | ConvertTo-Json -Compress
        [System.IO.File]::AppendAllText($fitnessFile, "$fitnessLine`n", [System.Text.Encoding]::UTF8)
        $results += "gene_fitness"
    } catch {
        # gene_fitness tracking is best-effort; log but don't break T2
        $failed += "gene_fitness: $($_.Exception.Message)"
    }
}

# ── 7. Retro-analyze trigger (every 10 tasks) ──────────────────
$retroScript = "$scriptsDir\gate\retro-analyze.ps1"
$counterPath = Join-Path $configDir "gates\.task-counter.json"
if (Test-Path $retroScript) {
    try {
        # Read counter, increment, check threshold
        # Handle both formats: new (proper JSON) and old (PowerShell hashtable literal)
        $counter = @{ count = 0; last = $null }
        if (Test-Path $counterPath) {
            $rawContent = Get-Content $counterPath -Raw
            if ($rawContent -match '^@\{') {
                # Old format: PowerShell hashtable literal — try to parse, fallback to defaults
                try { $counter = $rawContent | ConvertFrom-Json } catch { $counter = @{ count = 0; last = $null } }
            } else {
                try { $counter = Get-Content $counterPath -Raw | ConvertFrom-Json } catch { $counter = @{ count = 0; last = $null } }
            }
        }
        $newCount = $counter.count + 1
        $counter | Add-Member -NotePropertyName "count" -NotePropertyValue $newCount -Force
        $counter | Add-Member -NotePropertyName "last" -NotePropertyValue (Get-Date -Format o) -Force
        # Write as proper JSON (no BOM), not PowerShell hashtable literal
        $counter | ConvertTo-Json -Compress | Set-Content -Path $counterPath -Encoding UTF8 -NoNewline

        # Fire retro-analyze every 10 tasks
        if ($newCount % 10 -eq 0) {
            $retroOut = & powershell -NoProfile -File $retroScript -TaskCount 10 -WriteGenes 2>&1
            if ($LASTEXITCODE -eq 2) {
                $results += "retro-analyze-genes-written"
                # Note: evolution-agent review needed — flag for coordinator
                Write-Host "  [DNA] retro-analyze wrote genes — evolution-agent review needed" -ForegroundColor Yellow
            } else {
                $results += "retro-analyze"
            }
        }
    } catch {
        # counter file is best-effort; log but don't break T2
        $failed += "counter: $($_.Exception.Message)"
    }
}

# ── 8. Graph write (fire-and-forget) ──
$graphScript = "$scriptsDir\graph-memory.js"
$graphHelper = "$scriptsDir\graph-write-task.js"
if ((Test-Path $graphScript) -and (Test-Path $graphHelper)) {
    try {
        $safeName = $shortName -replace "[^a-zA-Z0-9-]", "-" -replace "-+", "-"
        $safeName = $safeName.Trim("-")
        if ($safeName.Length -gt 30) { $safeName = $safeName.Substring(0, 30) }

        # Get session name from session.yaml
        $sessionName = "unknown"
        if (Test-Path $yamlPath) {
            $yamlContent = Get-Content $yamlPath -Raw
            if ($yamlContent -match $sessionNamePattern) {
                $sessionName = $matches[1]
            }
        }

        # Call helper with proper argument passing
        $nodeOut = node $graphHelper $safeName $Agent $sessionName $graphScript 2>&1
        if ($nodeOut -and ($nodeOut -match "NODE:")) {
            $results += "graph_node"
        }
    } catch {
        $failed += "graph: $($_.Exception.Message)"
    }
}

# ── Output summary ──
$ok = $results.Count
$err = $failed.Count
Write-Host "T2 complete: $shortName" -ForegroundColor Cyan
Write-Host "  Steps OK: $($results -join ', ')" -ForegroundColor Green
if ($err -gt 0) {
    Write-Host "  Steps FAILED: $($failed -join '; ')" -ForegroundColor Yellow
}

# Exit with success unless all critical steps failed
if ($ok -eq 0) {
    exit 1
}
exit 0
