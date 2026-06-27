#!/usr/bin/env pwsh
# spec-inject.ps1
# Reads SPEC.md from current directory (or specified path) and emits context block.
# Zero-breaking: exits silently if no SPEC.md found.
# Pattern: GitHub Spec Kit (specs as living, executable artifacts)
# Usage: pwsh spec-inject.ps1 [-ProjectDir <path>] [-MaxBytes <int>]

param(
    [string]$ProjectDir = (Get-Location).Path,
    [int]$MaxBytes = 4000
)

$specFile = Join-Path $ProjectDir "SPEC.md"

if (-not (Test-Path $specFile)) {
    exit 0  # No spec — silent, zero impact
}

$content = Get-Content $specFile -Raw -ErrorAction SilentlyContinue
if (-not $content) {
    exit 0
}

if ($content.Length -gt $MaxBytes) {
    $content = $content.Substring(0, $MaxBytes) + "`n`n[...truncated, full SPEC.md at: $specFile]"
}

Write-Host "## Living SPEC (project context)"
Write-Host ""
Write-Host "Project: $ProjectDir"
Write-Host "Source: SPEC.md"
Write-Host ""
Write-Host $content
exit 0
