# save-checkpoint.ps1 — Atomic checkpoint with lock file
# Implements PROJECT_STATE_PERSISTENCE.md protocol exactly

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskId,
    [string]$TaskDescription = "",
    [int]$TotalSteps,
    [int]$CurrentStep = 1,
    [string]$ProjectDir = "",
    [string]$Status = "in_progress",
    [string]$SessionYamlPath = "$env:USERPROFILE\.config\opencode\memory\session.yaml",
    [string]$CheckpointDir = "$env:USERPROFILE\.config\opencode\memory"
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"
$checkpointPath = Join-Path $CheckpointDir "checkpoint.yaml"
$lockPath = "$checkpointPath.lock"
$tmpPath = "$checkpointPath.tmp"

# --- Lock file: prevent concurrent writes ---
if (Test-Path $lockPath) {
    $lockPid = (Get-Content $lockPath -Raw).Trim()
    if ($lockPid -and $lockPid -ne "$PID") {
        $otherProc = Get-Process -Id $lockPid -ErrorAction SilentlyContinue
        if ($otherProc) {
            Write-Host "SKIP checkpoint: locked by PID $lockPid ($($otherProc.ProcessName))"
            exit 0
        }
    }
    # Stale lock (process gone) — proceed
}
"$PID" | Out-File -FilePath $lockPath -Encoding UTF8

try {
    # --- Step 1: Sync to session.yaml (atomic via .tmp) ---
    if (Test-Path $SessionYamlPath) {
        $yaml = Get-Content $SessionYamlPath -Raw
        $yaml = $yaml -replace "`r`n", "`n"

        if (-not $TaskDescription) {
            if ($yaml -match "(?m)^\s+-\s+id:\s*$TaskId\s*\n(?:    .*\n)*?description:\s*`"(.+?)`"") {
                $TaskDescription = $matches[1]
            }
        }
        if (-not $TaskDescription) { $TaskDescription = "Multi-step task" }

        $escapedTaskDesc = $TaskDescription -replace '"', '\"'
        if ($yaml -match "(?m)^\s+-\s+id:\s*$TaskId\s*\n") {
            $yaml = $yaml -replace (
                "(?m)(^\s+-\s+id:\s*$TaskId\s*\n\s+description:\s*`"(.+?)`")",
                "`$1`n    step: $CurrentStep`n    of_steps: $TotalSteps`n    status: in_progress"
            )
        } else {
            $yaml = $yaml -replace "(tasks:\n)", (
                "tasks:`n  - id: $TaskId`n    description: `"$escapedTaskDesc`"`n    agent: coordinator`n    files: []`n    status: in_progress`n    step: $CurrentStep`n    of_steps: $TotalSteps`n    parent_poa: true`n"
            )
        }

        $yaml = $yaml -replace "`n", "`r`n"
        # Atomic write: .tmp → rename
        $yamlTmp = "$SessionYamlPath.tmp"
        $yaml | Out-File -FilePath $yamlTmp -Encoding UTF8
        Move-Item -Path $yamlTmp -Destination $SessionYamlPath -Force
    }

    # --- Step 2: Write checkpoint.yaml (atomic via .tmp → rename) ---
    $escapedTaskDesc = $TaskDescription -replace '"', '\"'
    $checkpoint = @"
# Checkpoint — $(Get-Date -Format 'yyyy-MM-dd HH:mm')
# Resume: powershell "$CheckpointDir\..\scripts\session_machine.ps1" -Trigger T1 -ResumeCheckpoint

task_id: $TaskId
task: "$escapedTaskDesc"
step: $CurrentStep
of: $TotalSteps
status: $Status
saved_at: "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')"
session_yaml: "$SessionYamlPath"
project_dir: "$ProjectDir"
next_action: "Continue step $($CurrentStep + 1) of $TotalSteps"
"@

    $checkpoint | Out-File -FilePath $tmpPath -Encoding UTF8
    Move-Item -Path $tmpPath -Destination $checkpointPath -Force

    $stepWord = if ($CurrentStep -eq 1) { "step" } else { "steps" }
    Write-Host "OK checkpoint saved: $CurrentStep/$TotalSteps $stepWord — $TaskDescription"
    Write-Host "   session.yaml updated (task $TaskId = step $CurrentStep/$TotalSteps)"
    Write-Host "   atomic write + lock confirmed"
}
finally {
    # Release lock
    if (Test-Path $lockPath) {
        Remove-Item $lockPath -Force -ErrorAction SilentlyContinue
    }
}