# Init-Project.ps1
# Bootstrap a project with OpenCode local config (.opencode/ folder).
# Lightweight: copies template files only, no external deps.
#
# Usage:
#   .\Init-Project.ps1              # Initialize current directory
#   .\Init-Project.ps1 -Path C:\my\project

param(
    [string]$Path = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$Template = "$HOME\.config\opencode\project-template"
$Target = Resolve-Path $Path

Write-Host ""
Write-Host "Init-Project -> $Target" -ForegroundColor Cyan

if (-not (Test-Path $Template)) {
    Write-Host "ERROR: Template not found at $Template" -ForegroundColor Red
    exit 1
}

# Files/folders to copy: AGENTS.md, opencode.json, .opencode/
$items = @(
    @{ Src = "$Template\AGENTS.md";     Dst = "$Target\AGENTS.md" },
    @{ Src = "$Template\opencode.json"; Dst = "$Target\opencode.json" },
    @{ Src = "$Template\.opencode";     Dst = "$Target\.opencode" }
)

foreach ($item in $items) {
    if (Test-Path $item.Dst) {
        Write-Host "  SKIP (exists): $($item.Dst)" -ForegroundColor Yellow
        continue
    }
    Copy-Item -Path $item.Src -Destination $item.Dst -Recurse -Force
    Write-Host "  OK:   $($item.Dst)" -ForegroundColor Green
}

# Replace {PROJECT_NAME} placeholder with actual folder name
$projectName = Split-Path $Target -Leaf
$memoryIndex = "$Target\.opencode\memory\MEMORY.md"
if (Test-Path $memoryIndex) {
    (Get-Content $memoryIndex -Raw).Replace('{PROJECT_NAME}', $projectName) | Set-Content $memoryIndex -NoNewline
}

# === ONBOARDING COMPLETENESS RULE ===
# All required files MUST exist before declaring done.
# Inspired by Agency-in-a-BOX's "ALL 5 files must exist" rule.
# Critical: partial initialization breaks downstream workflows.
$requiredFiles = @(
    "$Target\AGENTS.md"
    "$Target\opencode.json"
    "$Target\.opencode\memory\MEMORY.md"
)

$missing = @()
foreach ($f in $requiredFiles) {
    if (-not (Test-Path $f)) {
        $missing += $f
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: Incomplete initialization. Missing required files:" -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "  - $m" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "CRITICAL: All files must be created before proceeding." -ForegroundColor Yellow
    Write-Host "Do not run any OpenCode commands until this is resolved." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Done. Project initialized with:" -ForegroundColor Cyan
Write-Host "  - AGENTS.md          (fill in tech stack + conventions)"
Write-Host "  - opencode.json      (project permissions)"
Write-Host "  - .opencode/memory/  (project-local memory)"
Write-Host ""
Write-Host "Next: edit AGENTS.md with project-specific rules." -ForegroundColor Gray
