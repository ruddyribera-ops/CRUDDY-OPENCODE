param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,
    [string]$Agent = "unknown",
    [string]$Result = "Done",
    [string]$TokensEst = "~N",
    [string]$SessionLogPath = "$env:USERPROFILE\.config\opencode\memory\session_log.md"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SessionLogPath)) {
    "# Session Log" | Out-File -FilePath $SessionLogPath -Encoding UTF8
}
$content = Get-Content -Path $SessionLogPath -Raw
$content = $content -replace "`r`n", "`n"

$today = (Get-Date).ToString("yyyy-MM-dd")
$sessionHeader = "# Session Log - $today"

# Derive session name from session.yaml
$yamlPath = "$env:USERPROFILE\.config\opencode\memory\session.yaml"
if (Test-Path $yamlPath) {
    $yamlContent = Get-Content $yamlPath -Raw
    if ($yamlContent -match 'session_name:\s*"([^"]+)"') {
        $sessionName = $matches[1]
    } else {
        $sessionName = "Session $today"
    }
} else {
    $sessionName = "Session $today"
}

# Find the LAST occurrence of today's session header
$lastHeaderIndex = $content.LastIndexOf($sessionHeader)
if ($lastHeaderIndex -eq -1) {
    $newSection = @"

$sessionHeader

## $sessionName

| Task | Agent | Result | Tokens Est |
|------|-------|--------|-----------|
| $TaskName | $Agent | $Result | $TokensEst |
"@
    $content = $content.TrimEnd() + $newSection
} else {
    # Today's section exists -- find session name subsection (last occurrence)
    $sectionContent = $content.Substring($lastHeaderIndex)
    $sessionNameHeader = "## $sessionName"
    $nameIndex = $sectionContent.LastIndexOf($sessionNameHeader)

    if ($nameIndex -eq -1) {
        # Session name subsection doesn't exist -- create it after today's header
        $insertAt = $lastHeaderIndex + $sessionHeader.Length
        $before = $content.Substring(0, $insertAt)
        $after = $content.Substring($insertAt)
        $newSubSection = @"


## $sessionName

| Task | Agent | Result | Tokens Est |
|------|-------|--------|-----------|
| $TaskName | $Agent | $Result | $TokensEst |
"@
        $content = $before + $newSubSection + $after
    } else {
        # Subsection exists -- find its bounds
        $subsectionStart = $lastHeaderIndex + $nameIndex
        $afterSubsection = $content.Substring($subsectionStart)

        # Find end of subsection: next "## " or end of content
        $nextSubMatch = [regex]::Match($afterSubsection.Substring($sessionNameHeader.Length), '(?m)^## ')
        if ($nextSubMatch.Success) {
            $subsectionEnd = $subsectionStart + $sessionNameHeader.Length + $nextSubMatch.Index
        } else {
            $subsectionEnd = $content.Length
        }

        # Search for table header ONLY within subsection bounds
        $tableHeader = "| Task | Agent | Result | Tokens Est |"
        $tableHeaderPosInSub = $afterSubsection.IndexOf($tableHeader)

        if ($tableHeaderPosInSub -eq -1) {
            # No table in this subsection -- insert one
            $insertAt = $subsectionStart + $sessionNameHeader.Length
            $before = $content.Substring(0, $insertAt)
            $after = $content.Substring($insertAt)
            $newTable = @"


| Task | Agent | Result | Tokens Est |
|------|-------|--------|-----------|
| $TaskName | $Agent | $Result | $TokensEst |
"@
            $content = $before + $newTable + $after
        } else {
            # Table found -- check it's actually within subsection bounds
            $absoluteTablePos = $subsectionStart + $tableHeaderPosInSub

            if ($absoluteTablePos -ge $subsectionEnd) {
                # Table is AFTER this subsection ends (belongs to next subsection) -- insert new table
                $insertAt = $subsectionStart + $sessionNameHeader.Length
                $before = $content.Substring(0, $insertAt)
                $after = $content.Substring($insertAt)
                $newTable = @"


| Task | Agent | Result | Tokens Est |
|------|-------|--------|-----------|
| $TaskName | $Agent | $Result | $TokensEst |
"@
                $content = $before + $newTable + $after
            } else {
                # Table is within subsection bounds -- find last data row and append
                $tableContent = $content.Substring($absoluteTablePos)
                $lines = ($tableContent -split "`n")
                $lastDataRowIndex = -1
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $line = $lines[$i]
                    if ($line -match '^\s*\|' -and $line -notmatch '^\s*\|[-\s]+\|' -and $line -match '\w') {
                        $lastDataRowIndex = $i
                    }
                }
                if ($lastDataRowIndex -gt 0) {
                    $rowInsertPos = $absoluteTablePos
                    for ($i = 0; $i -le $lastDataRowIndex; $i++) {
                        $rowInsertPos += $lines[$i].Length + 1
                    }
                    $before = $content.Substring(0, $rowInsertPos)
                    $after = $content.Substring($rowInsertPos)
                    $newRow = "`n| $TaskName | $Agent | $Result | $TokensEst |"
                    $content = $before + $newRow + $after
                } else {
                    $content = $content + "`n| $TaskName | $Agent | $Result | $TokensEst |"
                }
            }
        }
    }
}

$content = $content -replace "`n", "`r`n"
Set-Content -Path $SessionLogPath -Value $content -Encoding UTF8
Write-Host "OK session_log.md updated: $TaskName"