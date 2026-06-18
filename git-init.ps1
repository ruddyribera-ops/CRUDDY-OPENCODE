Set-Location 'D:\Temp\cruddy-opencode'

Write-Host "Initializing git..."
git init
git config user.email "ruddyribera@gmail.com"
git config user.name "Ruddy Ribera"

Write-Host ""
Write-Host "Adding all files..."
git add -A

Write-Host ""
Write-Host "Git status (first 100 lines):"
git status 2>&1 | Select-Object -First 100

Write-Host ""
Write-Host "Committing..."
git commit -m "Initial commit: CRUDDY-OPENCODE v0.1.0

- Autoresearch skill (Karpathy pattern) for config self-improvement
- Hybrid memory retrieval (BM25 + vector + graph) - 100% local
- Pre-flight snapshot tools (PowerShell + Python)
- Incident-aware safety rule (born from 2026-06-17 PDC destruction)
- Consolidated structure: all system code under factory/
- 9 curated skills from open-source ecosystem
- codebase-memory MCP server integration
- MIT license

See README.md for quickstart.
See docs/PDC_INCIDENT_CAUTIONARY_TALE.md for the story."

$commit = git rev-parse HEAD
Write-Host ""
Write-Host "Commit SHA: $commit"