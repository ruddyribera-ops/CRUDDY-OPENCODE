# rotate-session-events.ps1
# Cron-style rotation — runs every 5 min via Windows Task Scheduler
# OR called from memory-bridge on every event (belt-and-suspenders)
param([int]$KeepLines = 10000)
$ErrorActionPreference = "SilentlyContinue"
$evPath = "$env:USERPROFILE\.config\opencode\memory\session_events.jsonl"
if (-not (Test-Path $evPath)) { exit 0 }
$lines = Get-Content $evPath
if ($lines.Count -le $KeepLines) { exit 0 }
$kept = $lines | Select-Object -Last $KeepLines
$removed = $lines.Count - $kept.Count
$kept | Set-Content "$evPath.tmp" -Encoding UTF8
Move-Item "$evPath.tmp" $evPath -Force
Write-Host "rotated: removed $removed old lines, kept $($kept.Count)"
exit 0