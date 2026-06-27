param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Requirement,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$TechStack = "auto"
)

function Invoke-UniversalBuilder {
    param(
        [string]$Req,
        [string]$Stack
    )

    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "[OpenCode] Universal Dev Team Builder" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""

    $agentsDir = "$env:USERPROFILE\Desktop\02_Proyectos\PRIA\PRIA v7\agents"
    $venvPath = Join-Path $agentsDir "venv"
    $pythonExe = Join-Path $venvPath "Scripts\python.exe"
    $builderScript = Join-Path $agentsDir "universal-builder.py"

    if (-not (Test-Path $pythonExe)) {
        Write-Host "[ERROR] Python venv not found at: $venvPath" -ForegroundColor Red
        Write-Host "[INFO] Please ensure venv is set up in the agents directory" -ForegroundColor Yellow
        return $false
    }

    if (-not (Test-Path $builderScript)) {
        Write-Host "[ERROR] universal-builder.py not found at: $builderScript" -ForegroundColor Red
        return $false
    }

    Write-Host "[Activating] Python venv at: $venvPath" -ForegroundColor Green
    Write-Host "[Requirement] $Req" -ForegroundColor Cyan
    Write-Host "[Tech Stack] $Stack" -ForegroundColor Cyan
    Write-Host ""

    try {
        $output = & $pythonExe $builderScript $Req $Stack 2>&1

        Write-Host $output

        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Green
        Write-Host "[OpenCode] Build orchestration complete" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Green
        Write-Host ""

        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to run builder: $_" -ForegroundColor Red
        return $false
    }
}

Invoke-UniversalBuilder -Req $Requirement -Stack $TechStack
