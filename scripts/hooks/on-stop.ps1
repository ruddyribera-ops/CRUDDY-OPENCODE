# on-stop.ps1 — Session-close handler
# Fires when Claude Code natural-stop occurs
# Input: JSON via stdin with session_id and transcript_path
# Behaviors: (A) skill proposal, (B) sprint date update, (C) lesson trigger

param()

$configDir = "$env:USERPROFILE\.config\opencode"
$memDir = "$configDir\memory"
$logFile = "$configDir\hook-errors.log"

# Helper: log errors to persistent location
function Log-HookError {
    param([string]$Message)
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] on-stop.ps1: $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    } catch {}
}

# --- Parse stdin ---
$transcriptPath = $null
try {
    $stdinRaw = [Console]::In.ReadToEnd()
    if ($stdinRaw -and $stdinRaw.Trim() -ne '') {
        $data = $stdinRaw | ConvertFrom-Json -ErrorAction Stop
        $transcriptPath = $data.transcript_path
    }
} catch {
    # stdin parse failure is non-fatal
}

# =========================================================
# Behavior A — Skill Proposal
# =========================================================
try {
    $toolCallCount = 0
    $lastLines = @()

    if ($transcriptPath -and (Test-Path $transcriptPath)) {
        $content = Get-Content $transcriptPath -Raw -ErrorAction Stop
        $lines = ($content -replace "`r`n", "`n") -split "`n"
        $toolCallCount = ($lines | Where-Object { $_ -match '"tool_name"' }).Count
        $lastLines = if ($lines.Count -gt 10) { $lines[($lines.Count - 10)..($lines.Count - 1)] } else { $lines }
    }

    $pendingFile = "$memDir\skill_proposal_pending.md"

    if ($toolCallCount -ge 5) {
        $today = Get-Date -Format 'yyyy-MM-dd'
        $context = $lastLines -join "`n"
        $pendingContent = @"
---
date: $today
tool_calls: $toolCallCount
transcript: $transcriptPath
---

# Skill Proposal Pending

This file was written by on-stop.ps1 because the session used $toolCallCount tool calls.
At next session start, Claude should assess whether the workflow is worth saving as a skill
and ask: "¿Guardo esto como un skill? Lo llamaría '[name]' — sirve para [use case]. (sí/no)"

## Last 10 transcript lines (context)
``````
$context
``````
"@
        [System.IO.File]::WriteAllText($pendingFile, $pendingContent, [System.Text.Encoding]::UTF8)
        Write-Host "[HOOK: skill-proposal] $toolCallCount tool calls detected. Pending file written."
    } else {
        if (Test-Path $pendingFile) { Remove-Item $pendingFile -Force }
        if ($toolCallCount -gt 0) {
            Write-Host "[HOOK: skill-proposal] $toolCallCount tool calls — below threshold, no proposal."
        }
    }
} catch {
    Log-HookError "Behavior A (skill-proposal) error: $_"
}

# =========================================================
# Behavior B — Sprint Date Update (idempotent)
# =========================================================
try {
    $sprintFile = "$memDir\current_sprint.md"
    if (Test-Path $sprintFile) {
        $today = Get-Date -Format 'yyyy-MM-dd'
        $sprintContent = Get-Content $sprintFile -Raw -ErrorAction Stop
        # Only update if today's date is not already there
        if ($sprintContent -notmatch [regex]::Escape($today)) {
            $updated = $sprintContent -replace '(?m)^\*\*Last updated:\*\*.*$', "**Last updated:** $today"
            [System.IO.File]::WriteAllText($sprintFile, $updated, [System.Text.Encoding]::UTF8)
            Write-Host "[HOOK: sprint] current_sprint.md updated to $today"
        } else {
            Write-Host "[HOOK: sprint] Already up to date ($today)"
        }
    }
} catch {
    Log-HookError "Behavior B (sprint-update) error: $_"
}

# =========================================================
# Behavior C — Lesson Trigger
# =========================================================
try {
    $lessonWorthy = $false
    $reason = ''

    if ($transcriptPath -and (Test-Path $transcriptPath)) {
        $content = Get-Content $transcriptPath -Raw -ErrorAction Stop
        $normalized = ($content -replace "`r`n", "`n").ToLower()

        # Heuristic: error/failed followed by fixed/works
        if (($normalized -match 'error|failed|exception') -and ($normalized -match 'fixed|resolved|works now|solved')) {
            $lessonWorthy = $true
            $reason = 'error-and-fix pattern detected'
        }

        # Heuristic: very complex session
        $lines = $normalized -split "`n"
        $toolCount = ($lines | Where-Object { $_ -match '"tool_name"' }).Count
        if ($toolCount -ge 8) {
            $lessonWorthy = $true
            $reason = "$toolCount tool calls (complex session)"
        }
    }

    $lessonPendingFile = "$memDir\lesson_pending.md"

    if ($lessonWorthy) {
        $today = Get-Date -Format 'yyyy-MM-dd'
        $lessonContent = @"
---
date: $today
reason: $reason
transcript: $transcriptPath
---

# Lesson Pending

This file was written by on-stop.ps1 ($reason).
At next session start, Claude should review and write a lessons_learned.md entry if appropriate.
"@
        [System.IO.File]::WriteAllText($lessonPendingFile, $lessonContent, [System.Text.Encoding]::UTF8)
        Write-Host "[HOOK: lesson] Pending lesson entry written — review in next session ($reason)"
    } else {
        if (Test-Path $lessonPendingFile) { Remove-Item $lessonPendingFile -Force }
    }
} catch {
    Log-HookError "Behavior C (lesson-trigger) error: $_"
}

# =========================================================
# Behavior D — Session Log Rotation (monthly archive)
# =========================================================
try {
    & "$configDir\scripts\rotate-session-log.ps1" -ErrorAction Stop
} catch {
    Log-HookError "Behavior D (rotate-session-log) error: $_"
}

# =========================================================
# Behavior E — Config Validation (quiet, failures only)
# =========================================================
try {
    & "$configDir\scripts\validate-config.ps1"
} catch {
    Log-HookError "Behavior E (validate-config) error: $_"
}

exit 0
