# Skill Version Check Script
# Validates that all skills have required frontmatter fields
# Run: powershell -File scripts/skill-version-check.ps1

param(
    [switch]$Fix,        # Auto-fix missing version fields
    [switch]$JsonOutput  # Output machine-readable JSON
)

$ErrorActionPreference = "Stop"
$opencodeRoot = "$env:USERPROFILE\.config\opencode"
$skillsDir = "$opencodeRoot\skills"

$requiredFields = @("name", "description", "version")
$skillsChecked = 0
$skillsPassed = 0
$skillsFailed = 0
$results = @()

Get-ChildItem -Path $skillsDir -Directory | ForEach-Object {
    $skillName = $_.Name
    $skillDir = $_.FullName
    $skillMd = "$skillDir\SKILL.md"

    $skillsChecked++

    if (-not (Test-Path $skillMd)) {
        $results += [PSCustomObject]@{
            Skill   = $skillName
            Status  = "ERROR"
            Message = "SKILL.md not found"
        }
        $skillsFailed++
        return
    }

    $content = Get-Content $skillMd -Raw
    $lines = ($content -replace "`r`n","`n") -split "`n"

    # Parse YAML frontmatter
    $inFrontmatter = $false
    $frontmatter = @{}
    $lineNumber = 0

    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match '^---$') {
            if (-not $inFrontmatter) {
                $inFrontmatter = $true
                continue
            } else {
                break  # End of frontmatter
            }
        }

        if ($inFrontmatter -and $line -match '^\s*(\w+):\s*(.*)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim()
            $frontmatter[$key] = $value
        }
    }

    # Validate required fields
    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $frontmatter.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($frontmatter[$field])) {
            $missingFields += $field
        }
    }

    # Version format check (semver)
    $versionOk = $true
    if ($frontmatter.ContainsKey("version")) {
        if ($frontmatter["version"] -notmatch '^\d+\.\d+\.\d+$') {
            $missingFields += "version (must be semver: X.Y.Z)"
            $versionOk = $false
        }
    }

    if ($missingFields.Count -eq 0) {
        $results += [PSCustomObject]@{
            Skill   = $skillName
            Status  = "PASS"
            Version = $frontmatter["version"]
        }
        $skillsPassed++
    } else {
        $results += [PSCustomObject]@{
            Skill         = $skillName
            Status        = "FAIL"
            MissingFields = $missingFields
            Message       = "Missing: $($missingFields -join ', ')"
        }
        $skillsFailed++
    }
}

# Also check skills in subdirectories (nested categories)
Get-ChildItem -Path $skillsDir -Include "SKILL.md" -Recurse | ForEach-Object {
    $skillMd = $_.FullName
    $skillDir = Split-Path $skillMd -Parent
    $skillName = (Split-Path $skillDir -Leaf)

    # Skip if already checked (top-level)
    if ($results.Skill -contains $skillName) { return }

    $skillsChecked++
    $content = Get-Content $skillMd -Raw
    $lines = ($content -replace "`r`n","`n") -split "`n"

    $inFrontmatter = $false
    $frontmatter = @{}

    foreach ($line in $lines) {
        if ($line -match '^---$') {
            if (-not $inFrontmatter) { $inFrontmatter = $true; continue }
            else { break }
        }
        if ($inFrontmatter -and $line -match '^\s*(\w+):\s*(.*)$') {
            $frontmatter[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    $missingFields = @()
    foreach ($field in $requiredFields) {
        if (-not $frontmatter.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($frontmatter[$field])) {
            $missingFields += $field
        }
    }

    if ($missingFields.Count -eq 0) {
        $results += [PSCustomObject]@{ Skill = $skillName; Status = "PASS"; Version = $frontmatter["version"] }
        $skillsPassed++
    } else {
        $results += [PSCustomObject]@{ Skill = $skillName; Status = "FAIL"; MissingFields = $missingFields }
        $skillsFailed++
    }
}

# Output
if ($JsonOutput) {
    $output = @{
        Timestamp    = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        TotalChecked = $skillsChecked
        Passed       = $skillsPassed
        Failed       = $skillsFailed
        Results      = $results
    }
    $output | ConvertTo-Json -Depth 5
    return
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SKILL VERSION CHECK" -ForegroundColor Cyan
Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Checked: $skillsChecked  |  Passed: $skillsPassed  |  Failed: $skillsFailed" -ForegroundColor $(if ($skillsFailed -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

$failures = $results | Where-Object { $_.Status -eq "FAIL" }

if ($failures) {
    Write-Host "FAILURES:" -ForegroundColor Red
    foreach ($f in $failures) {
        Write-Host "  [$($f.Skill)] $($f.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

$passes = $results | Where-Object { $_.Status -eq "PASS" }
if ($passes) {
    Write-Host "PASSED:" -ForegroundColor Green
    foreach ($p in $passes) {
        Write-Host "  [OK] $p"
    }
    Write-Host ""
}

if ($skillsFailed -eq 0) {
    Write-Host "RESULT: All skills have valid frontmatter." -ForegroundColor Green
    exit 0
} else {
    Write-Host "RESULT: $($skillsFailed) skill(s) need fixes." -ForegroundColor Yellow

    if ($Fix) {
        Write-Host "`n[AUTO-FIX] Adding missing frontmatter fields..." -ForegroundColor Cyan

        # Process all skills directories
        Get-ChildItem -Path $skillsDir -Directory | ForEach-Object {
            $skillDir = $_.FullName
            $skillName = $_.Name
            $skillMd = Join-Path $skillDir "SKILL.md"

            if (-not (Test-Path $skillMd)) { return }

            $content = Get-Content $skillMd -Raw
            $lines = $content -split "`n"

            $inFm = $false; $fmEndLine = -1; $lineIdx = 0
            foreach ($line in $lines) {
                if ($line -match '^---$') {
                    if (-not $inFm) { $inFm = $true; $fmStartLine = $lineIdx }
                    else { $fmEndLine = $lineIdx; break }
                }
                $lineIdx++
            }

            if ($fmEndLine -le 0) { return }  # No frontmatter

            # Get frontmatter WITHOUT the closing ---
            $fmLines = $lines[1..($fmEndLine - 1)]
            $fmText = ($fmLines -join "`n").TrimEnd()
            $afterFm = ($lines[($fmEndLine + 1)..($lines.Length - 1)] -join "`n").TrimStart()

            $newFm = $fmText
            $added = @()

            if ($newFm -notmatch '(?mi)^name:') {
                $newFm += "`nname: $skillName"
                $added += "name"
            }
            if ($newFm -notmatch '(?mi)^description:') {
                $newFm += "`ndescription: TODO - add description"
                $added += "description"
            }
            if ($newFm -notmatch '(?mi)^version:') {
                $newFm += "`nversion: 1.0.0"
                $added += "version"
            }
            if ($newFm -notmatch '(?mi)^platforms:') {
                $newFm += "`nplatforms: [windows, macos, linux]"
                $added += "platforms"
            }

            if ($added.Count -gt 0) {
                $newContent = "---`n" + $newFm + "`n---`n" + $afterFm
                # Write without trailing newline issues
                [System.IO.File]::WriteAllText($skillMd, $newContent, [System.Text.Encoding]::UTF8)
                Write-Host "  Fixed: $skillName (added: $($added -join ', '))" -ForegroundColor Green
            }
        }

        # Also fix nested SKILL.md files
        Get-ChildItem -Path $skillsDir -Include "SKILL.md" -Recurse | ForEach-Object {
            $skillMd = $_.FullName
            $skillDir = Split-Path $skillMd -Parent
            $skillName = Split-Path $skillDir -Leaf

            $content = Get-Content $skillMd -Raw
            $lines = $content -split "`n"

            $inFm = $false; $fmEndLine = -1; $lineIdx = 0
            foreach ($line in $lines) {
                if ($line -match '^---$') {
                    if (-not $inFm) { $inFm = $true }
                    else { $fmEndLine = $lineIdx; break }
                }
                $lineIdx++
            }
            if ($fmEndLine -le 0) { return }

            # Get frontmatter WITHOUT the closing ---
            $fmLines = $lines[1..($fmEndLine - 1)]
            $fmText = ($fmLines -join "`n").TrimEnd()
            $afterFm = ($lines[($fmEndLine + 1)..($lines.Length - 1)] -join "`n").TrimStart()

            $newFm = $fmText
            $added = @()

            if ($newFm -notmatch '(?mi)^name:') {
                $newFm += "`nname: $skillName"
                $added += "name"
            }
            if ($newFm -notmatch '(?mi)^description:') {
                $newFm += "`ndescription: TODO - add description"
                $added += "description"
            }
            if ($newFm -notmatch '(?mi)^version:') {
                $newFm += "`nversion: 1.0.0"
                $added += "version"
            }

            if ($added.Count -gt 0) {
                $newContent = "---`n" + $newFm + "`n---`n" + $afterFm
                [System.IO.File]::WriteAllText($skillMd, $newContent, [System.Text.Encoding]::UTF8)
                Write-Host "  Fixed: $skillName (nested, added: $($added -join ', '))" -ForegroundColor Green
            }
        }

        Write-Host "`n[DONE] Run without -Fix to verify." -ForegroundColor Cyan
    } else {
        Write-Host "`nRun with -Fix to auto-add missing version fields." -ForegroundColor DarkGray
    }

    exit 1
}
