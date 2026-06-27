param(
    [int]$MaxAgeDays = 7,
    [string]$HandoverDir = "$env:USERPROFILE\.config\opencode\memory\handover",
    [switch]$DryRun
)

<#
.SYNOPSIS
    Archives handovers older than N days
.DESCRIPTION
    Moves old handover files from handover/ to handover/archive/.
    Skips latest.md (current handover).
    Default: archives handovers older than 7 days.
.PARAMETER DryRun
    Show what would be archived without actually moving.
#>

$archiveDir = Join-Path $HandoverDir "archive"
if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$cutoff = (Get-Date).AddDays(-$MaxAgeDays)
$archived = 0
$skipped = 0

Get-ChildItem -Path $HandoverDir -Filter "*.md" | ForEach-Object {
    $file = $_
    
    # Skip latest.md (current handover)
    if ($file.Name -eq "latest.md") {
        $skipped++
        return
    }
    
    # Check age by filename date (handover-YYYY-MM-DD*.md) or last write time
    $fileDate = $file.LastWriteTime
    if ($file.Name -match "handover-(\d{4})-(\d{2})-(\d{2})") {
        try {
            $fileDate = Get-Date -Year $matches[1] -Month $matches[2] -Day $matches[3]
        } catch {}
    }
    
    if ($fileDate -lt $cutoff) {
        $dest = Join-Path $archiveDir $file.Name
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would archive: $($file.Name) (dated $($fileDate.ToString('yyyy-MM-dd')))"
        } else {
            Move-Item -Path $file.FullName -Destination $dest -Force
            Write-Host "  Archived: $($file.Name)"
        }
        $archived++
    }
    else {
        $skipped++
    }
}

$summary = "Handover archive: $archived archived, $skipped kept (cutoff: $($cutoff.ToString('yyyy-MM-dd')))"
if ($DryRun) { $summary = "[DRY RUN] $summary" }
Write-Host "`n$summary"
