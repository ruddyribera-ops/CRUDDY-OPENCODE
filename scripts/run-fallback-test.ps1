# Run OpenCode Fallback Chain Test
# Tests all configured providers in MiniMax -> Groq -> Gemini -> Cohere order

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  OpenCode Fallback Chain Test" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Set environment variables if they exist in user env
$envVars = @("MINIMAX_API_KEY", "GROQ_API_KEY", "GEMINI_API_KEY", "COHERE_API_KEY")
foreach ($var in $envVars) {
    $val = [System.Environment]::GetEnvironmentVariable($var, "User")
    if ($val) {
        $env:$var = $val
        Write-Host "[ENV] $var = SET" -ForegroundColor Green
    } else {
        Write-Host "[ENV] $var = NOT SET" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Running fallback chain test..." -ForegroundColor Cyan
Write-Host ""

# Run the TypeScript test script
node --experimental-strip-types "$env:USERPROFILE\.config\opencode\scripts\test-fallback-chain.ts"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan