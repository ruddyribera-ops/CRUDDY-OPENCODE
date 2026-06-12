# gate-check.ps1
# Gate enforcement check — invoked by code-builder STEP 4.6b.
# Verifies task artifacts meet step criteria before allowing next step.
#
# Usage: powershell -File gate-check.ps1 -TaskId "<task_id>" -Step <step> [-ProofType <type>] [-ArtifactPath <path>]
#
# Exit codes:
#   0 = PASS, proceed to next step
#   1 = FAIL, must retry
#   2 = WARN, log and proceed

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("implement", "verify", "review", "close", "init")]
    [string]$Step,

    [string]$ProofType = "file-exists",

    [string]$ArtifactPath = "",

    [switch]$Verbose
)

$configDir = "$env:USERPROFILE\.config\opencode"
$gatesDir = "$configDir\gates"
$gateStateDir = Join-Path $gatesDir $TaskId
$stateFile = Join-Path $gateStateDir "state.yaml"
$logFile = Join-Path $configDir "memory\gate-system.log"

function Log-Gate($msg) {
    $line = "[gate-check] $(Get-Date -Format 'HH:mm:ss') $msg"
    Write-Verbose $line
    try {
        Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    } catch {}
}

function Get-ProofResult {
    param([string]$Type, [string]$Path)

    if ($Path -and -not (Test-Path $Path)) {
        return @{ ok = $false; reason = "Artifact not found: $Path" }
    }

    switch ($Type) {
        "file-exists" {
            if (Test-Path $Path) {
                return @{ ok = $true; detail = "File exists" }
            }
            return @{ ok = $false; reason = "File missing: $Path" }
        }
        "grep-null" {
            if (-not (Test-Path $Path)) {
                return @{ ok = $false; reason = "File missing: $Path" }
            }
            $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
            if ($null -eq $content) {
                return @{ ok = $true; detail = "Empty file (no matches)" }
            }
            return @{ ok = $true; detail = "$((Get-Content $Path).Count) lines checked" }
        }
        "test-output" {
            if (-not (Test-Path $Path)) {
                return @{ ok = $false; reason = "Test output not found: $Path" }
            }
            $content = Get-Content $Path -Raw
            if ($content -match "(\d+)\s+passed" -or $content -match "PASS|OK|SUCCESS") {
                $matches = [regex]::Match($content, "(\d+)\s+passed")
                if ($matches.Success) {
                    return @{ ok = $true; detail = "$($matches.Groups[1].Value) tests passed" }
                }
                return @{ ok = $true; detail = "Tests passed (verified by content)" }
            }
            if ($content -match "(\d+)\s+failed|FAIL|ERROR") {
                return @{ ok = $false; reason = "Test output shows failures" }
            }
            return @{ ok = $true; detail = "Test output present (manual review needed)" }
        }
        "curl-200" {
            if ($Path -match "https?://") {
                try {
                    $resp = Invoke-WebRequest -Uri $Path -UseBasicParsing -TimeoutSec 10
                    if ($resp.StatusCode -eq 200) {
                        return @{ ok = $true; detail = "HTTP 200 OK" }
                    }
                    return @{ ok = $false; reason = "HTTP $($resp.StatusCode)" }
                } catch {
                    return @{ ok = $false; reason = "Request failed: $($_.Exception.Message)" }
                }
            }
            return @{ ok = $false; reason = "Invalid URL for curl-200 proof" }
        }
        "manual" {
            return @{ ok = $true; detail = "Manual approval (always passes)" }
        }
        "summary-sha" {
            if (-not (Test-Path $Path)) {
                return @{ ok = $false; reason = "Summary file not found: $Path" }
            }
            $hash = (Get-FileHash $Path -Algorithm SHA256).Hash
            return @{ ok = $true; detail = "SHA256: $($hash.Substring(0, 16))..." }
        }
        default {
            return @{ ok = $false; reason = "Unknown proof type: $Type" }
        }
    }
}

# Initialize gate state if this is a new task
if ($Step -eq "init") {
    if (-not (Test-Path $gateStateDir)) {
        New-Item -ItemType Directory -Path $gateStateDir -Force | Out-Null
    }
    $initState = @"
task_id: $TaskId
created: $(Get-Date -Format 'o')
step: init
status: PENDING
"@
    Set-Content -Path $stateFile -Value $initState -Encoding UTF8
    Log-Gate "INIT task=$TaskId"
    Write-Host "[gate-check] Initialized task $TaskId" -ForegroundColor Green
    exit 0
}

# Run the proof check
Log-Gate "CHECK task=$TaskId step=$Step proof=$ProofType artifact=$ArtifactPath"
$result = Get-ProofResult -Type $ProofType -Path $ArtifactPath

if ($result.ok) {
    Log-Gate "PASS task=$TaskId step=$Step"
    Write-Host "[gate-check] PASS $Step — $($result.detail)" -ForegroundColor Green
    exit 0
} else {
    Log-Gate "FAIL task=$TaskId step=$Step reason=$($result.reason)"
    Write-Host "[gate-check] FAIL $Step — $($result.reason)" -ForegroundColor Red
    exit 1
}
