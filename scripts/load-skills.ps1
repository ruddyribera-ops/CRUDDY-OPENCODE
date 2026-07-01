# load-skills.ps1
# Usage: powershell -File load-skills.ps1 -Skills "api-patterns,database-patterns"
# Returns skill content for coordinator context injection.

param(
    [string]$Skills = "",
    [string]$SkillsDir = "$env:USERPROFILE\.config\opencode\skills"
)

$ErrorActionPreference = "Stop"

if (-not $Skills) {
    Write-Output "# No skills specified"
    exit 0
}

$skillNames = $Skills -split ","
$output = @()

foreach ($name in $skillNames) {
    $name = $name.Trim()
    $skillPath = Join-Path $SkillsDir "$name/SKILL.md"

    if (-not (Test-Path $skillPath)) {
        $output += "# SKILL NOT FOUND: $name"
        continue
    }

    # Read content, skip frontmatter (lines between ---)
    $content = Get-Content $skillPath -Raw
    $content = $content -replace "`r`n", "`n"

    if ($content -match "(?s)^---\n.*?\n---\n(.*)") {
        $body = $matches[1]
        $output += "`n# === $name ===`n" + $body.Trim() + "`n"
    } else {
        $output += "`n# === $name (no frontmatter) ===`n" + $content.Trim() + "`n"
    }
}

$output -join "`n"