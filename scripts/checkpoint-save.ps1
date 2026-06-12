# checkpoint-save.ps1 - Saves a checkpoint snapshot for the current session
param(
    [Parameter(Mandatory=$true)]
    [string]$SessionId,

    [Parameter(Mandatory=$false)]
    [ValidateRange(0, 100)]
    [int]$ProgressPercent = 0,

    [Parameter(Mandatory=$false)]
    [string]$FilesModified = "",

    [Parameter(Mandatory=$false)]
    [string]$Strategy = "unknown",

    [Parameter(Mandatory=$false)]
    [string]$PendingTasks = "",

    [Parameter(Mandatory=$false)]
    [int]$AgentCount = 0,

    [Parameter(Mandatory=$false)]
    [string]$ActiveAgents = "",

    [Parameter(Mandatory=$false)]
    [string]$NextAction = "",

    [Parameter(Mandatory=$false)]
    [string]$CoordinatorDirectives = "",

    [Parameter(Mandatory=$false)]
    [string]$ErrorContext = "",

    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = $PWD.Path
)

$CONFIG_ROOT = $env:OPENCODE_CONFIG_HOME
if (-not $CONFIG_ROOT) {
    if ($env:USERPROFILE) { $CONFIG_ROOT = Join-Path $env:USERPROFILE ".config\opencode" }
    else { $CONFIG_ROOT = "C:\Users\Windows\.config\opencode" }
}

$ErrorActionPreference = "Stop"

$CHECKPOINT_DIR = Join-Path $CONFIG_ROOT "memory\checkpoints"
$INDEX_FILE = Join-Path $CHECKPOINT_DIR "checkpoint_index.jsonl"
$LATEST_LINK = Join-Path $CHECKPOINT_DIR "session_${SessionId}_latest.json"

if (-not (Test-Path $CHECKPOINT_DIR)) {
    New-Item -ItemType Directory -Path $CHECKPOINT_DIR -Force | Out-Null
}

$timestamp = (Get-Date).ToUniversalTime().ToString("o")
$checkpoint = @{
    session_id    = $SessionId
    created_at    = $timestamp
    progress_percent = $ProgressPercent
    files_modified = @($FilesModified -split "," | Where-Object { $_.Trim() -ne "" })
    strategy      = $Strategy
    agent_count   = $AgentCount
    active_agents = @($ActiveAgents -split "," | Where-Object { $_.Trim() -ne "" })
    pending_tasks = @($PendingTasks -split "," | Where-Object { $_.Trim() -ne "" })
    coordinator_directives = $CoordinatorDirectives
    error_context  = $ErrorContext
    next_action   = $NextAction
    project_path  = $ProjectPath
}

$json = $checkpoint | ConvertTo-Json -Depth 5 -Compress
$sessionFile = Join-Path $CHECKPOINT_DIR "session_${SessionId}_$([int][double]::Parse((Get-Date -UFormat %s))).json"
[System.IO.File]::WriteAllText($sessionFile, $json, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($LATEST_LINK, $json, [System.Text.Encoding]::UTF8)

$indexLine = @{
    type         = "checkpoint"
    session_id   = $SessionId
    timestamp    = $timestamp
    progress_percent = $ProgressPercent
    file         = (Split-Path $sessionFile -Leaf)
} | ConvertTo-Json -Compress

[System.IO.File]::AppendAllText($INDEX_FILE, "$indexLine`n", [System.Text.Encoding]::UTF8)

Write-Output "CHECKPOINT_SAVED:$($checkpoint.progress_percent)%|files=$($checkpoint.files_modified.Count)|$(Get-Date -Format HH:mm:ss)"
exit 0