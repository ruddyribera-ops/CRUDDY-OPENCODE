# auto-memory.ps1
# Automated end-of-task memory -- run after every task/sub-agent completes
param(
    [string]$TaskName,
    [string]$Agent,
    [string]$Result = "Done",
    [string]$TokensEst = "~N",
    [string]$ProjectDir = "",
    [string]$SprintNumber = "",
    [string]$TaskDescription = "",
    [string]$FilesModified = "",
    [switch]$NoSprintStamp,
    [switch]$NoLesson
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"
$scriptsDir = "$configDir\scripts"
$memoryDir = "$configDir\memory"
$logFile = "$configDir\hook-errors.log"

# T0: Auto-name session if session_name is still a placeholder
# Call session_machine.ps1 via & (dot-sourcing equivalent) instead of nested powershell -File
$sessionFile = "$memoryDir\session.yaml"
if (Test-Path $sessionFile) {
    # T0: Auto-name session if session_name is still a placeholder
    # Fire-T0 checks the current name and only renames if it matches the default pattern
    . "$scriptsDir\session_machine.ps1" -Trigger T0 -TaskName $TaskName -SessionYamlPath $sessionFile
}

$failed = @()

function Log-AutoMemError {
    param([string]$Msg)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$ts] auto-memory.ps1: $Msg" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# -- 1. Session Log (always) --
if ($TaskName) {
    $errCountBefore = $global:ERROR.Count
    & "$scriptsDir\append-session-log.ps1" -TaskName $TaskName -Agent $Agent -Result $Result -TokensEst $TokensEst -SessionLogPath "$memoryDir\session_log.md"
    $exitOk = $?
    if (-not $exitOk -or $global:ERROR.Count -gt $errCountBefore) {
        $failed += "session_log"
        Log-AutoMemError "append-session-log.ps1 failed for task='$TaskName'"
    }
    if ($ProjectDir) {
        $projectLog = Join-Path $ProjectDir ".opencode\memory\session_log.md"
        $projectLogDir = Split-Path $projectLog -Parent
        if (Test-Path $projectLogDir) {
            $errCountBefore = $global:ERROR.Count
            & "$scriptsDir\append-session-log.ps1" -TaskName $TaskName -Agent $Agent -Result $Result -TokensEst $TokensEst -SessionLogPath $projectLog
            if (-not $? -or $global:ERROR.Count -gt $errCountBefore) {
                $failed += "project_session_log"
                Log-AutoMemError "append-session-log.ps1 failed for project='$ProjectDir'"
            }
        }
    }
}

# -- 2. Sprint Stamp --
if ($SprintNumber -and $TaskDescription -and -not $NoSprintStamp) {
    $sprintMd = if ($ProjectDir) { Join-Path $ProjectDir ".opencode\memory\sprint-$SprintNumber.md" } else { $null }
    & "$scriptsDir\stamp-sprint.ps1" -TaskDescription "$TaskDescription" -SprintPath $sprintMd | Out-Null
}

# -- 3. Project Facts auto-refresh --
if ($ProjectDir) {
    $projectFacts = Join-Path $ProjectDir ".opencode\memory\project_active.md"
    if (Test-Path $projectFacts) {
        try {
            (Get-Item $projectFacts).LastWriteTime = [DateTime]::Now
        } catch {
            # File may be locked or read-only; non-fatal but should be logged
            Write-Warning "auto-memory: could not update LastWriteTime on $projectFacts - $($_.Exception.Message)"
        }
    }
}

# -- 4. Lessons-learned trigger --
if (-not $NoLesson -and $TaskName -and $TokensEst) {
    $tokensNum = 0
    [int]::TryParse($TokensEst.Replace("~", "").Trim(), [ref]$tokensNum) | Out-Null
    if ($tokensNum -gt 1500) {
        $lessonFile = Join-Path $memoryDir "lessons_learned.md"
        $today = Get-Date -Format 'yyyy-MM-dd'
        $existing = if (Test-Path $lessonFile) { Get-Content $lessonFile -Raw } else { "" }
        if ($existing -notmatch $today) {
            $entry = "`n## [$today] $TaskName`n**Context:** $Agent completed ($TokensEst tokens)`n**What happened:** Session auto-logged via auto-memory.ps1`n**Lesson:** Automation confirmed`n"
            Add-Content $lessonFile $entry -Encoding UTF8
        }
    }
}

# -- 5. Post-edit hook (auto-test after file changes) --
if ($FilesModified -and $FilesModified.Trim() -ne '') {
    try {
        $filesArray = $FilesModified -split ','
        foreach ($f in $filesArray) {
            $f = $f.Trim()
            if ($f -ne '') {
                $null = & "$scriptsDir\hooks\post-edit.ps1" -FilePath $f 2>&1
            }
        }
    } catch {
        Log-AutoMemError "post-edit.ps1 hook failed: $_"
    }
}

# -- 6. CASS auto-index (after session log, every 5 tasks) --
$taskCount = 0
$cassCounter = "$memoryDir\cass\.counter"
if (Test-Path $cassCounter) {
    $raw = (Get-Content $cassCounter -Raw).Trim()
    $taskCount = [int]($raw -split "`n")[0]
}
$nextCount = $taskCount + 1
$nextCount | Set-Content $cassCounter -Encoding UTF8
if ($nextCount % 5 -eq 0) {
    # Call with SilentlyContinue to avoid non-terminating errors poisoning $?
    # We only care about $LASTEXITCODE = 0 as success
    $cassOut = & "$scriptsDir\cass-index.ps1" -Verbose 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failed += "cass-index"
        Log-AutoMemError "cass-index.ps1 failed (exit=$LASTEXITCODE)"
    }
}

# -- 7. Self-audit --
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$status = if ($failed.Count -eq 0) { "OK" } else { "FAILED:$($failed -join ',')" }
"$ts auto-memory: task='$TaskName' agent='$Agent' result='$Result' tokens=$TokensEst status=$status" | Out-File -FilePath "$memoryDir\auto-memory.log" -Append -Encoding UTF8

if ($failed.Count -gt 0) {
    Write-Host "[auto-memory] completed with failures: $($failed -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "[auto-memory] done: $TaskName -- $Agent"
}

exit 0

