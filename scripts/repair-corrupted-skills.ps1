# Repair script for corrupted skill files
# Removes duplicate --- separators and ensures proper frontmatter structure

$skillsDir = "$env:USERPROFILE\.config\opencode\skills"

$corrupted = @(
    "api-patterns", "auth-patterns", "ci-cd-patterns", "code-review", "data-analysis",
    "database-patterns", "deployment-patterns", "git-workflow",
    "js-modern-patterns", "mmx-cli", "msoffice-tools",
    "python-patterns", "realtime-patterns", "security-basics",
    "skill-learning", "testing-standards", "ui-design"
)

foreach ($skillName in $corrupted) {
    $skillMd = "$skillsDir\$skillName\SKILL.md"
    if (-not (Test-Path $skillMd)) { continue }

    $content = Get-Content $skillMd -Raw
    $lines = ($content -replace "`r`n","`n") -split "`n"

    # Find the first two --- separators (proper frontmatter boundaries)
    $firstSep = -1
    $secondSep = -1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^---$') {
            if ($firstSep -eq -1) { $firstSep = $i }
            elseif ($secondSep -eq -1) { $secondSep = $i; break }
        }
    }

    if ($firstSep -eq -1 -or $secondSep -eq -1) {
        Write-Host "  SKIP: $skillName (no proper frontmatter found)"
        continue
    }

    # Extract original frontmatter (lines between first and second ---)
    $fmLines = $lines[($firstSep + 1)..($secondSep - 1)]
    $fmText = ($fmLines -join "`n").TrimEnd()

    # Get content after the frontmatter
    $afterFm = ($lines[($secondSep + 1)..($lines.Length - 1)] -join "`n").TrimStart()

    # Add missing fields
    $newFm = $fmText
    $added = @()

    if ($newFm -notmatch '(?mi)^version:') {
        $newFm += "`nversion: 1.0.0"
        $added += "version"
    }
    if ($newFm -notmatch '(?mi)^platforms:') {
        $newFm += "`nplatforms: [windows, macos, linux]"
        $added += "platforms"
    }

    # Reconstruct file with proper structure
    $newContent = "---`n$newFm`n---`n$afterFm"
    [System.IO.File]::WriteAllText($skillMd, $newContent, [System.Text.Encoding]::UTF8)

    if ($added.Count -gt 0) {
        Write-Host "  Fixed: $skillName (added: $($added -join ', '))"
    } else {
        Write-Host "  Repaired: $skillName (removed corrupted duplicates)"
    }
}

Write-Host "`n[DONE] Run skill-version-check.ps1 to verify."
