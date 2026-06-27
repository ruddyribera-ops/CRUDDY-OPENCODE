# OpenCode Power Setup — First-Time Initialization
# Run this after cloning the template repo

Write-Host "🔧 OpenCode Power Setup - Initialization" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if USER.md exists
if (-not (Test-Path "$PSScriptRoot\..\USER.md")) {
    Write-Host "📝 Creating USER.md from template..." -ForegroundColor Yellow
    Copy-Item "$PSScriptRoot\..\USER.template.md" "$PSScriptRoot\..\USER.md"
    Write-Host "   ⚠️  Edit USER.md with your personal info before using!" -ForegroundColor Red
} else {
    Write-Host "✅ USER.md already exists" -ForegroundColor Green
}

# 2. Copy memory templates
$memoryDir = "$PSScriptRoot\..\memory"
$templates = Get-ChildItem "$memoryDir\*.template.md"
foreach ($t in $templates) {
    $target = $t.FullName -replace '\.template\.md$', '.md'
    if (-not (Test-Path $target)) {
        Copy-Item $t.FullName $target
        Write-Host "📄 Created $target" -ForegroundColor Yellow
    }
}

# 3. Validate the agent registry
Write-Host ""
Write-Host "🧪 Validating agent registry..." -ForegroundColor Cyan
python "$PSScriptRoot\agent-registry.py" validate 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Agent registry valid" -ForegroundColor Green
} else {
    Write-Host "⚠️  Registry check had issues - inspect output above" -ForegroundColor Yellow
}

# 4. Summary
Write-Host ""
Write-Host "📋 Setup Complete!" -ForegroundColor Cyan
Write-Host "   Next steps:" -ForegroundColor White
Write-Host "   1. Edit USER.md with your name, projects, and preferences" -ForegroundColor Gray
Write-Host "   2. Add your API keys as Windows env vars:" -ForegroundColor Gray
Write-Host "      - OPENCODE_API_KEY (from opencode.ai)" -ForegroundColor Gray
Write-Host "      - BRAVE_API_KEY (from brave.com/search)" -ForegroundColor Gray
Write-Host "   3. Run: python scripts/agent-registry.py report" -ForegroundColor Gray
Write-Host "   4. Start using OpenCode!" -ForegroundColor Gray
