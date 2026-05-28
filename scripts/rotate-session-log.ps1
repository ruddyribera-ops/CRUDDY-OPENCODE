<#
.SYNOPSIS
    Rotates archived monthly sessions from session_log.md into dated archive files.
.DESCRIPTION
    Scans session_log.md for sessions by date header.
    Groups them by month. Any month older than the current calendar month gets
    archived to memory/session_logs/session_log_YYYY_MM.md and removed from
    the active session_log.md.
    Called by on-stop.ps1 (Behavior D) at session end.
.PARAMETER DryRun
    If true, shows what would be archived without modifying any files.
#>
param([switch]$DryRun)

$configDir = "$env:USERPROFILE\.config\opencode"
$sessionLog = "$configDir\memory\session_log.md"
$archiveDir = "$configDir\memory\session_logs"

function Log-HookError {
    param([string]$Message)
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] rotate-session-log: $Message" |
            Out-File -FilePath "$configDir\hook-errors.log" -Append -Encoding UTF8
    } catch {}
}

if (-not (Test-Path $sessionLog)) {
    Write-Host "[ROTATE] No session_log.md found -- nothing to rotate."
    exit 0
}

$raw = Get-Content $sessionLog -Raw -ErrorAction Stop
$lines = ($raw -replace "`r`n", "`n") -split "`n"

$allDates = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '# Session Log - (\d{4})-(\d{2})-\d{2}') {
        $allDates += @{ Line = $i; Year = [int]$Matches[1]; Month = [int]$Matches[2] }
    }
}

if ($allDates.Count -eq 0) {
    Write-Host "[ROTATE] No dated sessions found -- nothing to rotate."
    exit 0
}

$monthGroups = $allDates | Group-Object { "$($_.Year)-$($_.Month)" }
$today = Get-Date
$currentYear = $today.Year
$currentMonth = $today.Month

$archivedMonths = @()
$keptMonths = @()
foreach ($group in $monthGroups) {
    $parts = $group.Name -split '-'
    $y = [int]$parts[0]; $m = [int]$parts[1]
    if ($y -lt $currentYear -or ($y -eq $currentYear -and $m -lt $currentMonth)) {
        $archivedMonths += $group.Name
    } else {
        $keptMonths += $group.Name
    }
}

if ($archivedMonths.Count -eq 0) {
    Write-Host "[ROTATE] All sessions are current month -- no rotation needed."
    exit 0
}

Write-Host "[ROTATE] Archiving month(s): $($archivedMonths -join ', ')"
if ($DryRun) {
    Write-Host "[ROTATE] DRY RUN -- no files modified."
    exit 0
}

if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$boundaries = @()
foreach ($d in $allDates) { $boundaries += $d.Line }
$boundaries += $lines.Count

$sessionBlocks = @()
for ($i = 0; $i -lt $allDates.Count; $i++) {
    $sessionBlocks += @{
        Start = $allDates[$i].Line
        End   = $boundaries[$i + 1]
        MonthKey = "$($allDates[$i].Year)-$($allDates[$i].Month)"
        Year  = $allDates[$i].Year
        Month = $allDates[$i].Month
    }
}

$linesToKeep = @()
$archivedCount = 0
$seenArchive = @{}  # track which archive files we've started

$i = 0
while ($i -lt $lines.Count) {
    $block = $null
    foreach ($b in $sessionBlocks) {
        if ($i -ge $b.Start -and $i -lt $b.End) { $block = $b; break }
    }

    if ($block -and $block.MonthKey -in $archivedMonths) {
        $archiveKey = "$($block.Year)-$($block.Month.ToString('00'))"
        $archiveFile = "$archiveDir\session_log_$archiveKey.md"
        $lines[$i] | Out-File -FilePath $archiveFile -Encoding UTF8 -Append
        $archivedCount++
    } else {
        $linesToKeep += $lines[$i]
    }
    $i++
}

$newContent = ($linesToKeep -join "`n").TrimEnd()
if ($newContent.Length -eq 0) {
    $todayStr = Get-Date -Format 'yyyy-MM-dd'
    $newContent = "# Session Log - $todayStr`n`n"
}

[System.IO.File]::WriteAllText($sessionLog, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "[ROTATE] Archived $archivedCount lines across $($archivedMonths.Count) month(s)."
Write-Host "[ROTATE] session_log.md now contains only current month entries."
exit 0
