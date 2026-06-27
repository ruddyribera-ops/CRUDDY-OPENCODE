# Fix remaining 33 skills that have metadata block version or are missing fields

$skillsDir = "$env:USERPROFILE\.config\opencode\skills"

$remaining = @(
    "android-native-dev", "buddy-sings", "color-font-skill", "design-style-skill",
    "desktop-manager", "flutter-dev", "frontend-dev", "fullstack-dev",
    "gif-sticker-maker", "hermes-agent", "ios-application-dev", "minimax-docx",
    "minimax-multimodal-toolkit", "minimax-music-gen", "minimax-music-playlist",
    "minimax-pdf", "minimax-xlsx", "ocr-tools", "performance-optimization",
    "ppt-editing-skill", "ppt-orchestra-skill", "pptx-generator", "pr-review",
    "react-native-dev", "shader-dev", "slide-making-skill", "vision-analysis"
)

foreach ($skillName in $remaining) {
    $skillMd = "$skillsDir\$skillName\SKILL.md"
    if (-not (Test-Path $skillMd)) { continue }

    $content = Get-Content $skillMd -Raw
    # Handle both Windows and Unix line endings
    $lines = $content -replace "`r`n","`n" -split "`n"

    # Find frontmatter boundaries
    $firstSep = -1
    $secondSep = -1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^---$') {
            if ($firstSep -eq -1) { $firstSep = $i }
            elseif ($secondSep -eq -1) { $secondSep = $i; break }
        }
    }

    if ($firstSep -eq -1 -or $secondSep -eq -1) {
        Write-Host "  SKIP: $skillName (no proper frontmatter)"
        continue
    }

    # Extract frontmatter content
    $fmLines = $lines[($firstSep + 1)..($secondSep - 1)]
    $fmText = ($fmLines -join "`n").TrimEnd()
    $afterFm = ($lines[($secondSep + 1)..($lines.Length - 1)] -join "`n").TrimStart()

    # Check what's missing
    $hasToplevelName = $fmText -match '(?m)^name:'
    $hasToplevelDesc = $fmText -match '(?m)^description:'
    $hasToplevelVersion = $fmText -match '(?m)^version:'
    $hasToplevelPlatforms = $fmText -match '(?m)^platforms:'

    $newFm = $fmText
    $added = @()

    if (-not $hasToplevelName) {
        $newFm += "`nname: $skillName"
        $added += "name"
    }
    if (-not $hasToplevelDesc) {
        $newFm += "`ndescription: TODO - add description"
        $added += "description"
    }
    if (-not $hasToplevelVersion) {
        $newFm += "`nversion: 1.0.0"
        $added += "version"
    }
    if (-not $hasToplevelPlatforms) {
        $newFm += "`nplatforms: [windows, macos, linux]"
        $added += "platforms"
    }

    # Write back
    $newContent = "---`n$newFm`n---`n$afterFm"
    [System.IO.File]::WriteAllText($skillMd, $newContent, [System.Text.Encoding]::UTF8)

    if ($added.Count -gt 0) {
        Write-Host "  Fixed: $skillName (added: $($added -join ', '))"
    } else {
        Write-Host "  Checked: $skillName (already complete)"
    }
}

Write-Host "`n[DONE] Remaining skills fixed. Run skill-version-check.ps1 to verify."
