# gate-init.ps1
# Task gate initialization — sets up gate state for a new task.
# Invoked when code-builder starts a new multi-file task.
#
# Usage: powershell -File gate-init.ps1 -TaskId "<id>" -Description "<desc>"

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskId,

    [Parameter(Mandatory=$true)]
    [string]$Description
)

$configDir = "$env:USERPROFILE\.config\opencode"
$gatesDir = "$configDir\gates"
$taskDir = Join-Path $gatesDir $TaskId
$stateFile = Join-Path $taskDir "state.yaml"
$logFile = Join-Path $configDir "memory\gate-system.log"

# Validate task ID
if ($TaskId -notmatch "^[a-zA-Z0-9_-]+$") {
    Write-Host "[gate-init] Invalid task ID format: $TaskId" -ForegroundColor Red
    exit 1
}

# Create task gate directory
if (-not (Test-Path $taskDir)) {
    New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
}

# Initialize state.yaml
$state = @"
task_id: $TaskId
description: $Description
created: $(Get-Date -Format 'o')
status: PENDING
steps:
  implement: pending
  verify: pending
  review: pending
  close: pending
attempts: {}
blockers: []
"@
Set-Content -Path $stateFile -Value $state -Encoding UTF8

# Log
$line = "[gate-init] $(Get-Date -Format 'HH:mm:ss') INIT task=$TaskId desc=$Description"
try {
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
} catch {}

Write-Host "[gate-init] Initialized gate for task: $TaskId" -ForegroundColor Green
Write-Host "  State file: $stateFile" -ForegroundColor Gray
Write-Host "  Description: $Description" -ForegroundColor Gray
exit 0
