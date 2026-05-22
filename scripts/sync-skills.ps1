# Sync-Skills.ps1 — Bidirectional skill mirror for OpenCode ↔ Hermes

param(
    [ValidateSet("OpenCodeToHermes", "HermesToOpenCode")]
    [string]$Direction = "OpenCodeToHermes",

    [string]$SkillName = "",

    [switch]$DryRun,

    [switch]$Status
)

$ErrorActionPreference = "Stop"

# Paths
$OpenCodeSkills = "$env:USERPROFILE\.config\opencode\skills"
$HermesSkills = "$env:USERPROFILE\.hermes\skills"

# WSL path for Hermes (if on Windows with WSL)
$HermesSkillsWSL = "\\wsl$\Ubuntu\home\$env:USER\skills"
$WSLEnabled = $false

# Detect if WSL Hermes exists
if (Test-Path $HermesSkillsWSL) {
    $HermesSkills = $HermesSkillsWSL
    $WSLEnabled = $true
}

function Get-SkillInfo {
    param([string]$Path)
    if (!(Test-Path $Path)) { return @() }
    Get-ChildItem $Path -Directory | ForEach-Object {
        $skillDir = $_
        $skillFile = Join-Path $skillDir.FullName "SKILL.md"
        $lastMod = if (Test-Path $skillFile) { (Get-Item $skillFile).LastWriteTime } else { $null }
        [PSCustomObject]@{
            Name         = $skillDir.Name
            Path         = $skillDir.FullName
            SkillMdPath  = $skillFile
            Exists       = (Test-Path $skillFile)
            LastModified = $lastMod
        }
    }
}

function Show-Status {
    Write-Host "`n=== OpenCode Skills ===" -ForegroundColor Cyan
    $oc = Get-SkillInfo $OpenCodeSkills
    Write-Host "Count: $($oc.Count)"
    $oc | Sort-Object Name | Format-Table Name, Exists, LastModified -AutoSize

    Write-Host "`n=== Hermes Skills ===" -ForegroundColor Magenta
    if (Test-Path $HermesSkills) {
        $hs = Get-SkillInfo $HermesSkills
        Write-Host "Count: $($hs.Count)"
        $hs | Sort-Object Name | Format-Table Name, Exists, LastModified -AutoSize
    } else {
        Write-Host "Hermes skills dir not found: $HermesSkills" -ForegroundColor Yellow
    }
}

function Sync-Skill {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$Name
    )

    $srcFile = Join-Path $Src "$Name\SKILL.md"
    $dstFile = Join-Path $Dst "$Name\SKILL.md"

    if (!(Test-Path $srcFile)) {
        Write-Warning "Source not found: $srcFile"
        return $false
    }

    $action = "Would copy"
    if (!$DryRun) {
        # Backup existing
        if (Test-Path $dstFile) {
            $bak = "$dstFile.bak"
            Copy-Item $dstFile $bak -Force
            Write-Host "  Backup: $bak" -ForegroundColor DarkGray
        }
        # Create dir
        $dstDir = Split-Path $dstFile -Parent
        if (!(Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        # Copy
        Copy-Item $srcFile $dstFile -Force
        $action = "Copied"
    }

    Write-Host "  $action $Name -> $dst" -ForegroundColor Green
    return $true
}

# Main
if ($Status) {
    Show-Status
    exit 0
}

# Validate paths
if (!(Test-Path $OpenCodeSkills)) {
    Write-Error "OpenCode skills not found: $OpenCodeSkills"
}
if ($Direction -eq "HermesToOpenCode" -and !(Test-Path $HermesSkills)) {
    Write-Error "Hermes skills not found: $HermesSkills"
}

switch ($Direction) {
    "OpenCodeToHermes" {
        Write-Host "`n=== OpenCode -> Hermes ===" -ForegroundColor Cyan
        $src = $OpenCodeSkills
        $dst = $HermesSkills
    }
    "HermesToOpenCode" {
        Write-Host "`n=== Hermes -> OpenCode ===" -ForegroundColor Magenta
        $src = $HermesSkills
        $dst = $OpenCodeSkills
    }
}

if ($DryRun) {
    Write-Host "(DRY RUN - no files copied)" -ForegroundColor Yellow
}

if ($SkillName) {
    # Sync single skill
    Sync-Skill $src $dst $SkillName
} else {
    # Sync all
    $skills = Get-ChildItem $src -Directory
    $count = 0
    foreach ($skill in $skills) {
        if (Sync-Skill $src $dst $skill.Name) {
            $count++
        }
    }
    Write-Host "`nSynced $count skills" -ForegroundColor Green
}

Write-Host "`nDone." -ForegroundColor White