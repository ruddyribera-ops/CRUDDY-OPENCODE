# Dev Agency Launcher
# Usage: .\crew_start.ps1 "Add OAuth login to PRIA"
# Requires: CrewAI installed (uv pip install crewai crewai-tools)

param(
    [Parameter(Mandatory=$true)]
    [string]$Requirement,

    [Parameter(Mandatory=$false)]
    [string]$Workdir = $PWD,

    [Parameter(Mandatory=$false)]
    [string]$Model = "openrouter/openai/gpt-4o"
)

$ErrorActionPreference = "Stop"

$AGENT_DIR = "$env:USERPROFILE\.config\opencode\lib\agents"
$WORKFLOW_DIR = "$env:USERPROFILE\.config\opencode\lib\workflows"

Write-Host "🚀 Dev Agency" -ForegroundColor Cyan
Write-Host "   Requirement: $Requirement" -ForegroundColor Gray
Write-Host "   Workdir: $Workdir" -ForegroundColor Gray
Write-Host "   Model: $Model" -ForegroundColor Gray
Write-Host ""

# Check CrewAI installed
try {
    python -c "import crewai; print('CrewAI:', crewai.__version__)"
} catch {
    Write-Host "❌ CrewAI not installed. Run:" -ForegroundColor Red
    Write-Host "   uv pip install crewai crewai-tools langchain langchain-openai --system" -ForegroundColor Yellow
    exit 1
}

# Run the crew factory
try {
    $env:PYTHONPATH = "$env:USERPROFILE\.config\opencode\lib;$env:PYTHONPATH"
    python -c @"
import sys
sys.path.insert(0, r'$AGENT_DIR')
from crew_factory import DevAgency

agency = DevAgency(workdir=r'$Workdir'.replace('\\', '/'))
result = agency.execute_requirement(r'$Requirement')
print('\n✅ Result:', result)
"@
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}