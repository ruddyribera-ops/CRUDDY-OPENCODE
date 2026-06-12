# outcome-record.ps1 - Records a task outcome to patterns.jsonl
param(
    [Parameter(Mandatory=$true)]
    [string]$TaskType,

    [Parameter(Mandatory=$false)]
    [int]$DurationSeconds = 0,

    [Parameter(Mandatory=$false)]
    [int]$FilesTouched = 0,

    [Parameter(Mandatory=$false)]
    [int]$Errors = 0,

    [Parameter(Mandatory=$false)]
    [int]$RetryCount = 0,

    [Parameter(Mandatory=$false)]
    [string]$StrategyUsed = "unknown",

    [Parameter(Mandatory=$false)]
    [string]$Agent = "unknown",

    [Parameter(Mandatory=$false)]
    [ValidateSet(0,1)]
    [int]$Success = 1
)

$CONFIG_ROOT = $env:OPENCODE_CONFIG_HOME
if (-not $CONFIG_ROOT) {
    if ($env:USERPROFILE) { $CONFIG_ROOT = Join-Path $env:USERPROFILE ".config\opencode" }
    else { $CONFIG_ROOT = "C:\Users\Windows\.config\opencode" }
}

$ErrorActionPreference = "Stop"

$OUTCOMES_DIR = Join-Path $CONFIG_ROOT "memory\outcomes"
$PATTERNS_FILE = Join-Path $OUTCOMES_DIR "patterns.jsonl"

if (-not (Test-Path $OUTCOMES_DIR)) {
    New-Item -ItemType Directory -Path $OUTCOMES_DIR -Force | Out-Null
}

$entry = @{
    task_type       = $TaskType
    duration_seconds = $DurationSeconds
    files_touched   = $FilesTouched
    errors          = $Errors
    retry_count     = $RetryCount
    strategy_used   = $StrategyUsed
    agent           = $Agent
    success         = ($Success -eq 1)
    timestamp       = (Get-Date).ToUniversalTime().ToString("o")
}

$line = $entry | ConvertTo-Json -Compress
[System.IO.File]::AppendAllText($PATTERNS_FILE, "$line`n", [System.Text.Encoding]::UTF8)

$status = if ($Success) { "SUCCESS" } else { "FAILURE" }
Write-Output "RECORDED:$TaskType|${status}|${DurationSeconds}s|errors=$Errors"
exit 0