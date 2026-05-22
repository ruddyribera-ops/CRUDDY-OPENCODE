# generate-skill-index.ps1
# Scans skills directory and creates a JSON index for fast lookup
# v2 — Recursive, excludes backup dirs, UTF8 output, nested skill support

$skillsDir = "$env:USERPROFILE\.config\opencode\skills"
$outputFile = "$env:USERPROFILE\.config\opencode\skills\SKILLS_INDEX.json"

if (!(Test-Path $skillsDir)) {
    Write-Error "Skills directory not found: $skillsDir"
    exit 1
}

# Recursively find all SKILL.md files, excluding backup/phase dirs
$skillFiles = Get-ChildItem -Path $skillsDir -Recurse -Filter "SKILL.md" | Where-Object {
    $_.DirectoryName -notmatch '_phase\d+_backup_'
}

$index = @()

foreach ($file in $skillFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    
    # Extract frontmatter (simple regex)
    $frontmatter = @{}
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---") {
        $fmText = $matches[1]
        $fmText -split "\r?\n" | ForEach-Object {
            if ($_ -match "^\s*(\w+):\s*(.*)$") {
                $frontmatter[$matches[1]] = $matches[2].Trim()
            }
        }
    }
    
    # Build relative path from skillsDir
    $relPath = $file.FullName.Substring($skillsDir.Length + 1)
    
    $index += [PSCustomObject]@{
        Name        = $file.Directory.Name
        Description = $frontmatter["description"]
        Tags        = if ($frontmatter["tags"]) { $frontmatter["tags"] } else { "" }
        Version     = $frontmatter["version"]
        Triggers    = $frontmatter["triggers"]
        Path        = "skills/$relPath"
    }
}

# Sort by path for deterministic output
$sorted = $index | Sort-Object Path

$json = $sorted | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outputFile, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "Generated index with $($sorted.Count) skills at $outputFile"
