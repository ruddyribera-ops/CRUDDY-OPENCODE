param(
    [Parameter(Mandatory=$true)]
    [string]$TaskDescription,
    [string]$SprintPath = "$env:USERPROFILE\.config\opencode\memory\current_sprint.md",
    [switch]$SessionEnd
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SprintPath)) {
    $header = "# Current Sprint`n`nLast updated: $(Get-Date -Format 'yyyy-MM-dd')`n"
    $header | Out-File -FilePath $SprintPath -Encoding UTF8
}

$content = Get-Content -Path $SprintPath -Raw
$content = $content -replace "`r`n", "`n"
$today = Get-Date -Format "yyyy-MM-dd"

$entry = "- $today - $TaskDescription"

if ($SessionEnd) {
    $entry = "$entry [END]`n"
} else {
    $entry = "$entry`n"
}

# Find the Last Completed section and append
if ($content -match "(# Last Completed\n)") {
    $content = $content -replace "(# Last Completed\n)", "`$1$entry"
} else {
    $content = "$content`n## Last Completed`n$entry"
}

$content = $content -replace "`n", "`r`n"
$content | Out-File -FilePath $SprintPath -Encoding UTF8
Write-Host "OK sprint stamped: $TaskDescription"
