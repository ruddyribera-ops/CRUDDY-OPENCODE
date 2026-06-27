param(
    [string]$SessionYamlPath = "$env:USERPROFILE\.config\opencode\memory\session.yaml",
    [string]$HandoverDir = "$env:USERPROFILE\.config\opencode\memory\handover",
    [string]$ProjectActivePath = "$env:USERPROFILE\.config\opencode\memory\project_active.md",
    [string]$SprintPath = "$env:USERPROFILE\.config\opencode\memory\current_sprint.md",
    [switch]$Interim,
    [switch]$Crash,
    [string]$CrashMessage = ""
)

<#
.SYNOPSIS
    Generates handover/latest.md from session.yaml state
.DESCRIPTION
    Reads session.yaml, extracts all state, generates a structured handover document.
    Archives previous handover. Optionally generates interim (mid-session) or crash handovers.
.PARAMETER Interim
    Generate an interim handover (mid-session, not session end)
.PARAMETER Crash
    Generate a crash handover (minimal - what failed, last good state)
.PARAMETER CrashMessage
    What was happening when the crash occurred
#>

# ---- Read session.yaml ----
if (-not (Test-Path $SessionYamlPath)) {
    Write-Error "session.yaml not found at $SessionYamlPath"
    exit 1
}

$yamlContent = Get-Content -Path $SessionYamlPath -Raw
$yamlContent = $yamlContent -replace "`r`n", "`n"

# ---- Parse key fields via regex (no YAML parser needed) ----
function Get-YamlValue($yaml, $key) {
    if ($yaml -match "(?m)^$key:\s*`"(.+)`"\s*$") { return $matches[1] }
    if ($yaml -match "(?m)^$key:\s*(.+)\s*$") { return $matches[1] }
    return ""
}

function Get-YamlList($yaml, $key) {
    $result = @()
    if ($yaml -match "(?ms)$key:\n((?:  .*\n)*)") {
        $block = $matches[1]
        $block -split "`n" | ForEach-Object {
            if ($_ -match "^\s+-\s*`"(.+)`"") { $result += $matches[1] }
            elseif ($_ -match "^\s+-\s*(.+)") { $result += $matches[1] }
        }
    }
    return $result
}

function Get-Tasks($yaml) {
    $tasks = @()
    if ($yaml -match "(?ms)tasks:\n((?:  - .*\n(?:    .*\n)*)*)") {
        $block = $matches[1]
        $currentTask = @{}
        $block -split "`n" | ForEach-Object {
            if ($_ -match "^\s+-\s+id:\s*(\d+)") { if ($currentTask.Count -gt 0) { $tasks += $currentTask }; $currentTask = @{id=$matches[1]} }
            elseif ($_ -match "^\s+description:\s*`"(.+)`"") { $currentTask.description = $matches[1] }
            elseif ($_ -match "^\s+agent:\s*(.+)") { $currentTask.agent = $matches[1] }
            elseif ($_ -match "^\s+status:\s*(.+)") { $currentTask.status = $matches[1] }
            elseif ($_ -match "^\s+result:\s*`"(.+)`"") { $currentTask.result = $matches[1] }
            elseif ($_ -match "^\s+files:\s*(\[.+\])") { $currentTask.files = $matches[1] }
        }
        if ($currentTask.Count -gt 0) { $tasks += $currentTask }
    }
    return $tasks
}

$sessionName = Get-YamlValue $yamlContent "session_name"
$started = Get-YamlValue $yamlContent "started"
$decisions = Get-YamlList $yamlContent "decisions"
$lessons = Get-YamlList $yamlContent "lessons"
$stateBlock = ""
if ($yamlContent -match "(?ms)state:\n((?:  .*\n)*)") { $stateBlock = $matches[1] }
$nextSteps = Get-YamlList $yamlContent "next_steps"
$tasks = Get-Tasks $yamlContent

$completed = $tasks | Where-Object { $_.status -eq "completed" }
$pending = $tasks | Where-Object { $_.status -ne "completed" }
$filesChanged = @()
$tasks | ForEach-Object {
    if ($_.files -and $_.files -ne "[]") {
        $_files = $_.files -replace '[\[\]"]' -split ","
        $_files | ForEach-Object { $filesChanged += $_.Trim() }
    }
}
$filesChanged = $filesChanged | Select-Object -Unique

# ---- Determine project name ----
$projectName = "Unknown"
if ($yamlContent -match "projects_touched:\n\s+-\s+name:\s*`"(.+)`"") { $projectName = $matches[1] }

$today = (Get-Date).ToString("yyyy-MM-dd")
$prefix = if ($Interim) { "[INTERIM] " } elseif ($Crash) { "[CRASH] " } else { "" }

# ---- Archive previous handover ----
$latestPath = Join-Path $HandoverDir "latest.md"
$archiveDir = Join-Path $HandoverDir "archive"
if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
if (Test-Path $latestPath) {
    $archiveName = "handover-$(Get-Date -Format "yyyy-MM-dd-HHmm").md"
    Move-Item -Path $latestPath -Destination (Join-Path $archiveDir $archiveName) -Force
}

# ---- Generate handover ----
$handover = @"
# Handover: $today — ${prefix}$sessionName

"@

if ($Crash -and $CrashMessage) {
    $handover += @"
## ⚠️ CRASH HANDOVER

**What was happening:** $CrashMessage

**This is a recovery handover.** The session ended unexpectedly. Review state and decide whether to resume or restart.

"@
}

$handover += "## Context`n"
if ($Interim) {
    $handover += "Interim handover — session still in progress. Generated at $(Get-Date -Format 'HH:mm').`n"
}

$handover += @"
Session started: $started
Project: $projectName
Tasks completed: $($completed.Count)/$($tasks.Count)

## What Was Done

"@

if ($completed.Count -eq 0) {
    $handover += "_No tasks completed yet._`n"
} else {
    $i = 1
    $completed | ForEach-Object {
        $handover += "$i. $($_.description) — $($_.result)`n"
        $i++
    }
}

$handover += @"

## What's Pending

"@

if ($pending.Count -eq 0 -and $nextSteps.Count -eq 0) {
    $handover += "_Nothing pending._`n"
} else {
    $i = 1
    $pending | ForEach-Object {
        $handover += "$i. ⬜ $($_.description)`n"
        $i++
    }
    $nextSteps | ForEach-Object {
        $handover += "$i. ⬜ $_`n"
        $i++
    }
}

$handover += @"

## Key Decisions

"@

if ($decisions.Count -eq 0) {
    $handover += "_None recorded._`n"
} else {
    $decisions | ForEach-Object { $handover += "- $_`n" }
}

$handover += @"

## State Snapshot

"@

if ($stateBlock) {
    $stateBlock -split "`n" | ForEach-Object {
        if ($_ -match "^\s+(.+?):\s*(.+)$") {
            $handover += "- **$($matches[1]):** $($matches[2])`n"
        }
    }
}

$handover += @"

## Files Changed/Created

"@

if ($filesChanged.Count -eq 0) {
    $handover += "_None._`n"
} else {
    $filesChanged | ForEach-Object { $handover += "- $_`n" }
}

# ---- Write handover ----
$handover | Out-File -FilePath $latestPath -Encoding UTF8
Write-Host "✅ handover/latest.md written"

# ---- Update current_sprint.md ----
if (-not $Interim -and -not $Crash) {
    $sprintContent = Get-Content -Path $SprintPath -Raw -ErrorAction SilentlyContinue
    if (-not $sprintContent) { $sprintContent = "# Current Sprint`n`n" }
    $sprintContent = $sprintContent -replace "`r`n", "`n"
    
    $newEntry = "- $today — $sessionName: $($completed.Count) tasks completed. ✅`n"
    
    if ($sprintContent -match "(# Last Completed\n)") {
        $sprintContent = $sprintContent -replace "(# Last Completed\n)", "`$1$newEntry"
    } else {
        $sprintContent += "`n## Last Completed`n$newEntry"
    }
    
    $sprintContent = $sprintContent -replace "`n", "`r`n"
    $sprintContent | Out-File -FilePath $SprintPath -Encoding UTF8
    Write-Host "✅ current_sprint.md stamped"
}

# ---- Summary for user notification ----
$summary = @"
📋 Handover saved — $sessionName
✅ $($completed.Count) tasks done
⬜ $($pending.Count) pending
📁 $($filesChanged.Count) files changed
"@

# Output summary to stdout for the coordinator to display
Write-Host "`n$summary"
