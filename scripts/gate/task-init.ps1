# task-init.ps1
# Creates a new task state file in gates/<task_id>/state.yaml
# Run this at the START of every task
param(
    [string]$TaskId = "",
    [string]$Description = "",
    [string]$ProjectDir = "",
    [switch]$Force
)
$ErrorActionPreference = "Stop"
$gateRoot = "$env:CONFIG\gates"

if (-not $TaskId) {
    $date = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $TaskId = "task-$date"
}

$taskDir = Join-Path $gateRoot $TaskId
$stateFile = Join-Path $taskDir "state.yaml"

if ((Test-Path $stateFile) -and -not $Force) {
    Write-Output "[TASK-INIT] Task '$TaskId' already exists. Use -Force to reset."
    exit 0
}

$projectName = if ($ProjectDir) { Split-Path $ProjectDir -Leaf } else { Split-Path $PWD -Leaf }

New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $taskDir "artifacts") -Force | Out-Null

$yaml = @"
task_id: "$TaskId"
description: "$Description"
project: "$projectName"
created: "$(Get-Date -Format o)"
current_step: "implement"
status: "in_progress"

steps:
  implement:
    status: pending
    proof_sha: null
    proof_type: null
    agent: null
    completed: null
    gate_passed: false
    blocked_reason: null
    attempts: 0
    required_proof: "varies"

  verify:
    status: pending
    proof_sha: null
    proof_type: null
    agent: null
    completed: null
    gate_passed: false
    blocked_reason: null
    attempts: 0
    required_proof: "varies"

  review:
    status: pending
    proof_sha: null
    proof_type: null
    agent: null
    completed: null
    gate_passed: false
    blocked_reason: null
    attempts: 0
    required_proof: "manual"

  close:
    status: pending
    proof_sha: null
    proof_type: null
    agent: null
    completed: null
    gate_passed: false
    blocked_reason: null
    attempts: 0
    required_proof: "summary-sha"

history: []

metadata:
  init_script: "task-init.ps1"
  config_root: "$env:CONFIG"
  closed_by: null
  completion_note: null
"@

Set-Content -Path $stateFile -Value $yaml -NoNewline

# Log to auto-memory.log
$logLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') task-init: id=$TaskId project=$projectName"
$logFile = Join-Path $env:CONFIG "memory\auto-memory.log"
Add-Content -Path $logFile -Value $logLine -ErrorAction SilentlyContinue

Write-Output "[TASK-INIT] Task '$TaskId' created."
Write-Output "         Dir: $taskDir"
Write-Output "         Step: implement"
Write-Output "         Next: gate-check.ps1 -TaskId $TaskId -Step implement ..."
exit 0
