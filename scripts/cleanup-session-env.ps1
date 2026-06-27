# cleanup-session-env.ps1
# Cleans old .claude/session-env directories older than 14 days.
# Run: standalone (manual) or wired from memory-bridge.js session.deleted
param(
    [int]$MaxAgeDays = 14,
    [switch]$WhatIf
)

$TargetDir = "$env:USERPROFILE\.claude\session-env"
if (-not (Test-Path $TargetDir)) { exit 0 }

$Cutoff = (Get-Date).AddDays(-$MaxAgeDays)
$old = Get-ChildItem -Path $TargetDir -Directory -ErrorAction SilentlyContinue |
       Where-Object { $_.LastWriteTime -lt $Cutoff }

if ($WhatIf) {
    Write-Host "[WhatIf] Would remove $($old.Count) old session-env directories"
    exit 0
}

if ($old.Count -eq 0) {
    Write-Host "[cleanup-session-env] No old directories (all < $MaxAgeDays days)"
    exit 0
}

$removed = $old | Remove-Item -Recurse -Force -PassThru
Write-Host "[cleanup-session-env] Removed $($removed.Count) old session-env directories (>$MaxAgeDays days)"