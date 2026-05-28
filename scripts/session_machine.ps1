# T1-T8 Session Lifecycle Orchestrator
# Enforces TRIGGERS.md — NOT dependent on coordinator judgment.
param(
    [Parameter(Mandatory=$false)]
    [string]$Trigger = "T2",
    [string]$TaskId = "",
    [string]$TaskName = "",
    [string]$Agent = "",
    [string]$Result = "Done",
    [string]$TokensEst = "~N",
    [string]$TaskDescription = "",
    [string]$ProjectDir = "",
    [string]$SprintNumber = "",
    [string]$Files = "[]",

    [string]$LessonTitle = "",
    [string]$LessonContext = "",
    [string]$WhatHappened = "",
    [string]$Lesson = "",
    [string]$Category = "workflow",

    [string]$Decision = "",
    [string]$DecisionContext = "",
    [string]$Alternatives = "",
    [string]$Rationale = "",

    [string]$Project = "",
    [string]$WhatChanged = "",

    [string]$To = "",
    [string]$Subject = "",
    [string]$Body = "",
    [switch]$Urgent,

    [switch]$CheckpointFound,
    [string]$HandoverPath = "",

    [switch]$Interim,
    [switch]$Crash,
    [string]$CrashMessage = "",

    [string]$SessionYamlPath = "",
    [string]$MemoryDir = ""
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"
$scriptsDir = "$configDir\scripts"
$memoryDir = "$configDir\memory"
$kgWritePx = "python `"$scriptsDir\kg_write_proxygen.py`""

if (-not $SessionYamlPath) { $SessionYamlPath = "$memoryDir\session.yaml" }
if (-not $MemoryDir) { $MemoryDir = $memoryDir }

# ============================================================
# T0 - FIRST TASK / SESSION AUTO-NAME
# ============================================================
function Fire-T0 {
    param([string]$FirstTaskName = "")

    Write-Host "T0: First task -- $FirstTaskName"

    if (-not $FirstTaskName) {
        Write-Host "   T0 requires -FirstTaskName. Skipping."
        return
    }

    if (Test-Path $SessionYamlPath) {
        try {
            $yaml = Get-Content $SessionYamlPath -Raw
            $yaml = $yaml -replace "`r`n", "`n"

            # Match if session name starts with "Session " followed by a date pattern
            if ($yaml -match 'session_name:\s*"Session \d{4}-\d{2}-\d{2}[^"]*"') {
                $cleanName = $FirstTaskName.Trim()
                if ($cleanName.Length -gt 50) {
                    $cleanName = $cleanName.Substring(0, 47) + "..."
                }
                $cleanName = $cleanName -replace '"', ''
                
                # Robust replacement using regex capture for the rest of the file
                $pattern = '(?m)^session_name:\s*".*?"'
                $replacement = "session_name: `"$cleanName`""
                $yaml = [regex]::Replace($yaml, $pattern, $replacement)
                
                $yaml = $yaml -replace "`n", "`r`n"
                Set-Content -Path $SessionYamlPath -Value $yaml -Encoding UTF8
                Write-Host "   Session named: $cleanName"
            } else {
                if ($yaml -match 'session_name:\s*"([^"]+)"') {
                    Write-Host "   Session already named: $($matches[1])"
                }
            }
        } catch {
            Write-Host "   T0 failed: $_"
        }
    }
}

# ============================================================
# T1 - SESSION START
# ============================================================
function Fire-T1 {
    Write-Host "T1: Session Start"

    $checkpointPath = "$memoryDir\checkpoint.yaml"
    if (Test-Path $checkpointPath) {
        Write-Host "   Checkpoint found: offer resume"
        $cp = Get-Content $checkpointPath -Raw
        if ($cp -match 'task:\s*"(.+)"') { Write-Host "      Task: $($matches[1])" }
        if ($cp -match 'step:\s*(\d+)\s+of\s+(\d+)') { Write-Host "      Step: $($matches[1])/$($matches[2])" }
        Write-Host "      Run with -ResumeCheckpoint to continue"
        return
    }

    $handoverFile = "$memoryDir\handover\latest.md"
    if (Test-Path $handoverFile) {
        Write-Host "   Handover loaded from: $handoverFile"
        $content = Get-Content $handoverFile -Raw
        if ($content -match '(?s)## What Was Done\s*\n(.+?)## What.s Pending') {
            $done = $matches[1].Trim()
            $lines = ($done -split "`n" | Where-Object { $_.Trim() -and $_ -notmatch '^#' })
            Write-Host "   $($lines.Count) tasks completed in prior session"
        }
    }

    $trackScript = "$scriptsDir\track-tokens.ps1"
    if (Test-Path $trackScript) {
        & $trackScript -Action "reset" | Out-Null
    }

    $sessionId = "Session-$(Get-Date -Format 'yyyy-MM-dd')"
    $sessionFile = "$memoryDir\session.yaml"

    $resetNeeded = $false
    if (Test-Path $sessionFile) {
        $oldYaml = Get-Content $sessionFile -Raw
        $lastWrite = (Get-Item $sessionFile).LastWriteTime
        $now = Get-Date
        $diff = $now - $lastWrite

        if ($oldYaml -match 'started:\s*"(\d{4}-\d{2}-\d{2})') {
            if ($matches[1] -ne (Get-Date -Format 'yyyy-MM-dd')) {
                $resetNeeded = $true
                Write-Host "   Session is from a previous day ($($matches[1])). Resetting."
            } elseif ($diff.TotalHours -gt 1.5) {
                $resetNeeded = $true
                Write-Host "   Session is stale ($($diff.TotalMinutes) min idle). Resetting."
            }
        }
    } else {
        $resetNeeded = $true
    }

    if ($resetNeeded) {
        $newYaml = "session_name: `"Session $(Get-Date -Format 'yyyy-MM-dd HH:mm')`"`n"
        $newYaml += "started: `"$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`"`n"
        $newYaml += "projects_touched: []`n"
        $newYaml += "tasks: []`n"
        $newYaml += "decisions: []`n"
        $newYaml += "lessons: []`n"
        $newYaml += "blockers: []`n"
        $newYaml += "files_changed: []`n"
        $newYaml += "state: {}`n"
        $newYaml += "next_steps: []`n"
        $newYaml | Out-File -FilePath $sessionFile -Encoding UTF8
    }

    $today = Get-Date -Format 'yyyy-MM-dd'
    $kgCmd = "entity `"$sessionId`" `"session`" `"date:$today,status:in_progress`""
    Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" $kgCmd" 2>$null | Out-Null

    Write-Host "   Session initialized: $sessionId"
}

# ============================================================
# T2 - TASK COMPLETE
# ============================================================
function Fire-T2 {
    Write-Host "T2: Task Complete - $TaskName ($Agent)"

    if (-not $TaskName) {
        Write-Host "   T2 requires -TaskName. Skipping."
        return
    }

    $appendScript = "$scriptsDir\append-session-log.ps1"
    if (Test-Path $appendScript) {
        & $appendScript -TaskName $TaskName -Agent $Agent -Result $Result -TokensEst $TokensEst -SessionLogPath "$memoryDir\session_log.md" | Out-Null
    }

    if (Test-Path $SessionYamlPath) {
        try {
            $yaml = Get-Content $SessionYamlPath -Raw
            $yaml = $yaml -replace "`r`n", "`n"

            $taskCount = ([regex]::Matches($yaml, '^\s+- id:\s+\d+', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count  
            $nextId = $taskCount + 1

            $escapedTask = $TaskName -replace '"', '\"'
            $escapedResult = $Result -replace '"', '\"'
            $newLines = @"

  - id: $nextId
    description: "$escapedTask"
    agent: "$Agent"
    files: $Files
    status: completed
    tokens_est: $TokensEst
    duration_min: 0
    result: "$escapedResult"
"@
            if ($yaml -match '(tasks:\n(?:  - .*\n)*)') {
                $block = $matches[0]
                $yaml = $yaml.Replace($block, $block + $newLines)
                $yaml = $yaml -replace "`n", "`r`n"
                Set-Content -Path $SessionYamlPath -Value $yaml -Encoding UTF8
            }
        } catch {}
    }

    $tokenNum = 0
    [int]::TryParse($TokensEst.Replace("~", "").Trim(), [ref]$tokenNum) | Out-Null
    if ($tokenNum -gt 0 -and $Agent) {
        $trackScript = "$scriptsDir\track-tokens.ps1"
        if (Test-Path $trackScript) {
            & $trackScript -Action "add" -Agent $Agent -Tokens $tokenNum | Out-Null
        }
    }

    if ($SprintNumber -and $TaskDescription) {
        $stampScript = "$scriptsDir\stamp-sprint.ps1"
        if (Test-Path $stampScript) {
            & $stampScript -TaskDescription $TaskDescription -SprintPath "$memoryDir\current_sprint.md" | Out-Null
        }
    }

    if ($Agent) {
        $kgCmd = "entity `"Session-$(Get-Date -Format 'yyyy-MM-dd')`" `"session`" `"last_task:$TaskName,status:working`""
        Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" $kgCmd" 2>$null | Out-Null
    }

    Write-Host "   T2 complete"
}

# ============================================================
# T3 - SESSION END
# ============================================================
function Fire-T3 {
    if ($Crash) {
        Write-Host "T3: Session CRASH - $CrashMessage"
    } else {
        Write-Host "T3: Session End"
    }

    $sessionId = "Session-$(Get-Date -Format 'yyyy-MM-dd')"
    $statusVal = if ($Crash) { "crashed" } else { "completed" }
    $kgCmd = "entity `"$sessionId`" `"session`" `"status:$statusVal,ended:$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`""
    Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" $kgCmd" 2>$null | Out-Null

    Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" flush" 2>$null | Out-Null

    $checkpointPath = "$memoryDir\checkpoint.yaml"
    if (Test-Path $checkpointPath) {
        Remove-Item $checkpointPath -Force -ErrorAction SilentlyContinue
        Write-Host "   Checkpoint cleared"
    }

    $sessionFile = "$memoryDir\session.yaml"
    if (Test-Path $sessionFile) {
        try {
            $yaml = Get-Content $sessionFile -Raw
            if ($yaml -match 'session_name:\s*"([^"]+)"') { $sessionName = $matches[1] } else { $sessionName = "Session" }
            $taskCount = ([regex]::Matches($yaml, '^\s+- id:\s+\d+', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count  
            if ($taskCount -gt 0) {
                $handoverDir = "$memoryDir\handover"
                if (-not (Test-Path $handoverDir)) { New-Item -ItemType Directory -Path $handoverDir -Force | Out-Null }
                $today = Get-Date -Format 'yyyy-MM-dd'
                $hc = @"
# Handover -- $sessionName

## When
$today

## What Was Done
- ($taskCount tasks in this session)

## What's Pending
-

## Key Decisions
-

## Next Steps
1.
"@
                $hc | Out-File -FilePath "$handoverDir\latest.md" -Encoding UTF8
                Write-Host "   Handover written: $handoverDir\latest.md"
            }
        } catch {}
    }

    Write-Host "   T3 complete"
}

# ============================================================
# T4 - STATUS QUERY
# ============================================================
function Fire-T4 {
    Write-Host "T4: Status Query"

    $memoryDir = "$env:USERPROFILE\.config\opencode\memory"
    $sessionFile = "$memoryDir\session.yaml"
    $handoverFile = "$memoryDir\handover\latest.md"
    $projectFile = "$memoryDir\project_active.md"

    # 1. Session state
    $sessionName = "Unknown"
    $started = "unknown"
    $tasks = @()
    $decisions = @()
    $blockers = @()
    $filesChanged = @()
    $state = @{}

    if (Test-Path $sessionFile) {
        $yaml = Get-Content $sessionFile -Raw
        if ($yaml -match 'session_name:\s*"([^"]+)"') { $sessionName = $matches[1] }
        if ($yaml -match 'started:\s*"([^"]+)"') { $started = $matches[1] }
        if ($yaml -match 'blockers:\s*\n((  - .+\n)*)') { $blockers = $matches[1] -split '\n' | Where-Object { $_ -match '  - ' } | ForEach-Object { $_.Trim() -replace '^  - ', '' } }
        if ($yaml -match 'decisions:\s*\n((  - .+\n)*)') { $decisions = $matches[1] -split '\n' | Where-Object { $_ -match '  - ' } | ForEach-Object { $_.Trim() -replace '^  - ', '' } }
        if ($yaml -match 'files_changed:\s*\n((  - .+\n)*)') { $filesChanged = $matches[1] -split '\n' | Where-Object { $_ -match '  - ' } | ForEach-Object { $_.Trim() -replace '^  - ', '' } }
        # Parse tasks
        if ($yaml -match 'tasks:\s*\n((  - .+\n)*)') {
            $taskBlock = $matches[1]
            $taskMatches = [regex]::Matches($taskBlock, '^\s+- id:\s+(\d+)\s*\n\s+description:\s+"([^"]+)"\s*\n\s+status:\s+(\w+)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
            foreach ($m in $taskMatches) {
                $tasks += @{ id = $m.Groups[1].Value; description = $m.Groups[2].Value; status = $m.Groups[3].Value }
            }
        }
        # Parse state key-values
        if ($yaml -match 'state:\s*\n((  \w+:\s+.+\n)*)') {
            $stateBlock = $matches[1]
            $stateMatches = [regex]::Matches($stateBlock, '^\s+(\w+):\s+(.+)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
            foreach ($sm in $stateMatches) {
                $state[$sm.Groups[1].Value.Trim()] = $sm.Groups[2].Value.Trim()
            }
        }
    }

    # 2. Handover context
    $handoverContent = ""
    if (Test-Path $handoverFile) {
        $handoverContent = Get-Content $handoverFile -Raw
    }

    # 3. Project facts
    $projectContent = ""
    if (Test-Path $projectFile) {
        $projectContent = Get-Content $projectFile -Raw
    }

    # 4. KG recent sessions
    $kgSessions = @()
    try {
        $kgScript = "$env:USERPROFILE\.config\opencode\scripts\kg_write_proxygen.py"
        $result = Invoke-Expression "python `"$kgScript`" search `"session`" 2>`$null" | Out-String
        if ($result) {
            $kgSessions = $result -split "`n" | Where-Object { $_ -match 'Session-' }
        }
    } catch {}

    # 5. Compute duration
    $duration = "unknown"
    if ($started -ne "unknown") {
        try {
            $startTime = [DateTime]::Parse($started)
            $duration = [Math]::Round(((Get-Date) - $startTime).TotalMinutes)
            $duration = "${duration}min"
        } catch {}
    }

    # 6. Build output
    $completed = $tasks | Where-Object { $_.status -eq 'completed' }
    $pending = $tasks | Where-Object { $_.status -ne 'completed' }

    $output = @"

====================  STATUS  ====================
Session: $sessionName
Started: $started ($duration ago)
Projects: $(if ($state['projects_touched']) { ($state['projects_touched'] -split ',')[0] } else { 'none' })

TASKS: $($completed.Count)/$($tasks.Count) done
"@
    foreach ($t in $completed) { $output += "  ✅ [$($t.id)] $($t.description)`n" }
    foreach ($t in $pending)   { $output += "  ⬜ [$($t.id)] $($t.description)`n" }

    $output += "`nDECISIONS:`n"
    if ($decisions.Count -gt 0 -and $decisions[0] -ne '') {
        foreach ($d in $decisions) { $output += "  → $d`n" }
    } else { $output += "  (none)`n" }

    $output += "`nBLOCKERS:`n"
    if ($blockers.Count -gt 0 -and $blockers[0] -ne '') {
        foreach ($b in $blockers) { $output += "  ⚠ $($b)`n" }
    } else { $output += "  (none)`n" }

    $output += "`nFILES CHANGED: $($filesChanged.Count)`n"
    foreach ($f in $filesChanged | Select-Object -First 10) { $output += "  $f`n" }

    if ($handoverContent) {
        $output += "`nHANDOVER CONTEXT:`n"
        $output += "  (see memory/handover/latest.md)`n"
    }

    $output += "`n==============================================`n"

    Write-Host $output

    Write-Host "   T4 complete"
}

# ============================================================
# T5 - LESSON LEARNED
# ============================================================
function Fire-T5 {
    Write-Host "T5: Lesson -- $LessonTitle"

    if (-not $Lesson) {
        Write-Host "   T5 requires -Lesson. Skipping."
        return
    }

    $lessonFile = "$memoryDir\lessons_learned.md"
    $today = Get-Date -Format 'yyyy-MM-dd'
    $entry = @"

## [$today] $LessonTitle
**Context:** $LessonContext
**What happened:** $WhatHappened
**Lesson:** $Lesson
**Category:** $Category
"@
    if (-not (Test-Path $lessonFile)) { "# Lessons Learned" | Out-File -FilePath $lessonFile -Encoding UTF8 }
    Add-Content -Path $lessonFile -Value $entry -Encoding UTF8

    $lessonId = "Lesson-$today-$(Get-Random -Maximum 999)"
    $kgCmd = "entity `"$lessonId`" `"lesson`" `"category:$Category,title:$LessonTitle`" `"$Lesson`""
    Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" $kgCmd" 2>$null | Out-Null

    Write-Host "   Lesson saved"
}

# ============================================================
# T6 - ARCHITECTURE DECISION
# ============================================================
function Fire-T6 {
    Write-Host "T6: Decision -- $Decision"

    if (-not $Decision) {
        Write-Host "   T6 requires -Decision. Skipping."
        return
    }

    if (Test-Path $SessionYamlPath) {
        try {
            $yaml = Get-Content $SessionYamlPath -Raw
            $yaml = $yaml -replace "`r`n", "`n"
            $escapedDecision = $Decision -replace '"', '\"'
            if ($yaml -match '(?ms)(decisions:\s*\n)') {
                $yaml = $yaml -replace '(?ms)(decisions:\s*\n)', "`$1  - `"$escapedDecision`"`n"
            }
            $yaml = $yaml -replace "`n", "`r`n"
            Set-Content -Path $SessionYamlPath -Value $yaml -Encoding UTF8
        } catch {}
    }

    $kgCmd = "entity `"Decision-$(Get-Date -Format 'yyyy-MM-dd')`" `"decision`" `"decision:$Decision`" `"context:$DecisionContext`""   
    Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" $kgCmd" 2>$null | Out-Null

    Write-Host "   Decision logged"
}

# ============================================================
# T7 - PROJECT STATE CHANGE
# ============================================================
function Fire-T7 {
    Write-Host "T7: Project -- $Project"

    if (-not $Project) {
        Write-Host "   T7 requires -Project. Skipping."
        return
    }

    $projectFacts = "$ProjectDir\.opencode\memory\project_active.md"
    if (Test-Path $projectFacts) {
        (Get-Item $projectFacts).LastWriteTime = [DateTime]::Now
    }

    $kgCmd = "entity `"$Project`" `"project`" `"last_changed:$(Get-Date -Format 'yyyy-MM-dd'),changed:$WhatChanged`""
    Invoke-Expression "python `"$scriptsDir\kg_write_proxygen.py`" $kgCmd" 2>$null | Out-Null

    Write-Host "   Project facts updated"
}

# ============================================================
# T8 - INTER-AGENT MAIL
# ============================================================
function Fire-T8 {
    Write-Host "T8: Mail to $To"

    if (-not $To -or -not $Subject) {
        Write-Host "   T8 requires -To and -Subject. Skipping."
        return
    }

    $subj = if ($Subject) { $Subject } else { "" }
    $body = if ($Body) { $Body } else { "" }
    $urgentFlag = if ($Urgent) { " [URGENT]" } else { "" }

    $mailScript = "$scriptsDir\mail.py"
    $fullCmd = "python `"$mailScript`" send `"$To`" --subject `"$subj$urgentFlag`" --body `"$body`""
    $result = Invoke-Expression $fullCmd 2>$null

    if ($result -match '"ok":\s*true') {
        Write-Host "   Mail sent to $To`: $subj"
    } else {
        Write-Host "   Mail failed: $result"
    }
}

# ============================================================
# MAIN DISPATCHER
# ============================================================
switch ($Trigger) {
    "T0" { Fire-T0 -FirstTaskName $TaskName -SessionYamlPath $SessionYamlPath }
    "T1" { Fire-T1 }
    "T2" { Fire-T2 }
    "T3" { Fire-T3 }
    "T4" { Fire-T4 }
    "T5" { Fire-T5 }
    "T6" { Fire-T6 }
    "T7" { Fire-T7 }
    "T8" { Fire-T8 }
    default {
        Write-Host "Unknown trigger: $Trigger"
        Write-Host "Valid: T0, T1, T2, T3, T4, T5, T6, T7, T8"
    }
}
