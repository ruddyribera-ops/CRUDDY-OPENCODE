# cleanup-checkpoints.ps1 — Clean up stale checkpoint files from memory/checkpoints/
# Usage: cleanup-checkpoints.ps1 [-CheckpointsDir <path>] [-MaxAgeHours <int>] [-MaxKeep <int>] [-DryRun]
#
# Deletes checkpoint files older than MaxAgeHours.
# Keeps at least MaxKeep of the most recent files regardless of age.
# Designed to be run at session start. Idempotent.

param(
    [string]$CheckpointsDir = "$env:USERPROFILE\.config\opencode\memory\checkpoints",
    [int]$MaxAgeHours = 24,
    [int]$MaxKeep = 3,
    [switch]$DryRun
)

if (-not (Test-Path -LiteralPath $CheckpointsDir)) {
    Write-Output "No checkpoints directory at $CheckpointsDir - nothing to clean."
    exit 0
}

$cutoff = (Get-Date).AddHours(-$MaxAgeHours)
$allFiles = Get-ChildItem -LiteralPath $CheckpointsDir -File | Sort-Object LastWriteTime -Descending
$keep = $allFiles | Select-Object -First $MaxKeep
$remove = $allFiles | Where-Object { $_.LastWriteTime -lt $cutoff -and $_.FullName -notin $keep.FullName }

if ($remove.Count -eq 0) {
    Write-Output "Nothing to clean. Kept $($keep.Count) most recent file(s)."
    exit 0
}

if ($DryRun) {
    Write-Output "DRY RUN: would delete $($remove.Count) file(s):"
    foreach ($f in $remove) {
        Write-Output "  $($f.Name)  (last write: $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    }
    exit 0
}

$deleted = 0
foreach ($f in $remove) {
    try {
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
        $deleted++
    } catch {
        Write-Warning "Could not delete $($f.FullName): $_"
    }
}
Write-Output "Cleanup complete: deleted $deleted file(s), kept $($keep.Count) most recent."
exit 0
