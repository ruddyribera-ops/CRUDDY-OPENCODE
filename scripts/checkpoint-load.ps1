# checkpoint-load.ps1 - Loads the latest checkpoint for a session (or the most recent overall)
param(
    [Parameter(Mandatory=$false)]
    [string]$SessionId = ""
)

$ErrorActionPreference = "Stop"

$CONFIG_ROOT = $env:OPENCODE_CONFIG_HOME
if (-not $CONFIG_ROOT) {
    if ($env:USERPROFILE) { $CONFIG_ROOT = Join-Path $env:USERPROFILE ".config\opencode" }
    else { throw "OPENCODE_CONFIG_HOME and USERPROFILE are both unset - cannot determine config root" }
}

$CHECKPOINT_DIR = Join-Path $CONFIG_ROOT "memory\checkpoints"
$INDEX_FILE = Join-Path $CHECKPOINT_DIR "checkpoint_index.jsonl"

if ($SessionId -ne "") {
    $latestPath = Join-Path $CHECKPOINT_DIR "session_${SessionId}_latest.json"
    if (Test-Path $latestPath) {
        $content = [System.IO.File]::ReadAllText($latestPath, [System.Text.Encoding]::UTF8)
        $cp = $content | ConvertFrom-Json
        Write-Output "LOADED:session=$($cp.session_id)|progress=$($cp.progress_percent)%|files=$($cp.files_modified.Count)"
        exit 0
    } else {
        Write-Output "NO_CHECKPOINT:session $SessionId not found"
        exit 1
    }
} else {
    if (Test-Path $INDEX_FILE) {
        $lines = [System.IO.File]::ReadAllLines($INDEX_FILE, [System.Text.Encoding]::UTF8)
        $validLines = @()
        foreach ($line in $lines) {
            if ($line -ne "") {
                try {
                    $parsed = $line | ConvertFrom-Json
                    if ($parsed.type -eq "checkpoint") { $validLines += $parsed }
                } catch {}
            }
        }
        if ($validLines.Count -gt 0) {
            $latest = $validLines | Sort-Object { $_.timestamp } -Descending | Select-Object -First 1
            $checkpointFile = Join-Path $CHECKPOINT_DIR $latest.file
            if (Test-Path $checkpointFile) {
                $content = [System.IO.File]::ReadAllText($checkpointFile, [System.Text.Encoding]::UTF8)
                $cp = $content | ConvertFrom-Json
                $age = [int](((Get-Date).ToUniversalTime() - [DateTime]::Parse($cp.created_at)).TotalMinutes)
                Write-Output "LOADED:session=$($cp.session_id)|progress=$($cp.progress_percent)%|age=${age}m"
                exit 0
            }
        }
    }
    Write-Output "NO_CHECKPOINT:no checkpoints found"
    exit 1
}