# gate-check.ps1
# Gate Enforcer - exit 0 = pass, exit 1 = block
# MUST be called before any agent declares done
param(
    [string]$TaskId,
    [string]$Step,
    [string]$ProofType,
    [string]$ArtifactPath = "",
    [string]$Pattern = ""
)
$ErrorActionPreference = "Stop"
$gateRoot = "$env:CONFIG\gates"
$taskDir = "$gateRoot\$TaskId"
$stateFile = Join-Path $taskDir "state.yaml"

if (-not (Test-Path $stateFile)) {
    Write-Output "[GATE ERROR] No state file for task $TaskId"
    exit 1
}

# Read current state
$lines = Get-Content $stateFile
$inStep = $false
$gatePassed = $false
$currentAttempts = 0

foreach ($l in $lines) {
    if ($l -match "^  $Step\.") { $inStep = $true; continue }
    if ($inStep -and $l -match "^  \w" -and $l -notmatch "^  $Step") { break }
    if ($l -match "gate_passed:\s*(\w+)") { $gatePassed = ($matches[1] -eq "true") }
    if ($l -match "attempts:\s*(\d+)") { $currentAttempts = [int]$matches[1] }
}

if ($gatePassed) {
    Write-Output "[GATE SKIP] Step $Step already passed"
    exit 0
}

$proofValid = $false
$actualSHA = ""

switch ($ProofType) {
    "file-exists" {
        if (Test-Path $ArtifactPath) {
            $proofValid = $true
            $actualSHA = (Get-FileHash $ArtifactPath -Algorithm SHA256).Hash
            Write-Output "[GATE PASSED] $Step file-exists: $ArtifactPath SHA: $actualSHA"
        } else {
            Write-Output "[GATE BLOCKED] $Step file not found: $ArtifactPath"
        }
    }
    "grep-null" {
        if (Test-Path $ArtifactPath -and $Pattern) {
            $result = Select-String -Path $ArtifactPath -Pattern $Pattern -Quiet
            if (-not $result) {
                $proofValid = $true
                $actualSHA = "grep-null-clean"
                Write-Output "[GATE PASSED] $Step grep-null clean"
            } else {
                Write-Output "[GATE BLOCKED] $Step pattern found in file"
            }
        } else {
            Write-Output "[GATE BLOCKED] $Step file or pattern missing"
        }
    }
    "test-output" {
        if ((Test-Path $ArtifactPath) -and (Get-Content $ArtifactPath -Raw).Length -gt 10) {
            $proofValid = $true
            $actualSHA = (Get-FileHash $ArtifactPath -Algorithm SHA256).Hash
            $artifactDir = Join-Path $taskDir "artifacts"
            New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
            Copy-Item $ArtifactPath "$artifactDir\test-$Step-$actualSHA.txt" -Force
            Write-Output "[GATE PASSED] $Step test-output SHA: $actualSHA"
        } else {
            Write-Output "[GATE BLOCKED] $Step test output missing or empty"
        }
    }
    "curl-200" {
        try {
            $r = Invoke-WebRequest -Uri $ArtifactPath -Method GET -TimeoutSec 10 -ErrorAction SilentlyContinue
            if ($r.StatusCode -eq 200) {
                $proofValid = $true
                $actualSHA = "curl-200"
                Write-Output "[GATE PASSED] $Step curl-200 OK"
            } else {
                Write-Output "[GATE BLOCKED] $Step curl status: $($r.StatusCode)"
            }
        } catch {
            Write-Output "[GATE BLOCKED] $Step curl failed"
        }
    }
    "manual" {
        $proofValid = $true
        $actualSHA = "manual-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Write-Output "[GATE PASSED] $Step manual confirmation"
    }
    "summary-sha" {
        if ((Test-Path $ArtifactPath) -and (Get-Content $ArtifactPath -Raw).Length -gt 50) {
            $proofValid = $true
            $actualSHA = (Get-FileHash $ArtifactPath -Algorithm SHA256).Hash
            Write-Output "[GATE PASSED] $Step summary SHA: $actualSHA"
        } else {
            Write-Output "[GATE BLOCKED] $Step summary missing or too short"
        }
    }
}

if (-not $proofValid) { exit 1 }

# Update state file
$newLines = @()
$inStep = $false
$stepDone = $false

foreach ($l in (Get-Content $stateFile)) {
    if ($l -match "^  $Step\.") { $inStep = $true }
    if ($inStep -and $l -match "^  \w" -and $l -notmatch "^  $Step") { $inStep = $false }

    if ($inStep) {
        if ($l -match "^    gate_passed:") { $newLines += "    gate_passed: true"; $stepDone = $true }
        elseif ($l -match "^    proof_sha:") { $newLines += "    proof_sha: $actualSHA" }
        elseif ($l -match "^    status:") { $newLines += "    status: done" }
        elseif ($l -match "^    attempts:") { $newLines += "    attempts: $($currentAttempts + 1)" }
        elseif ($l -match "^    completed:") { $newLines += "    completed: $(Get-Date -Format o)" }
        elseif ($l -match "^    blocked_reason:") { $newLines += "    blocked_reason: null" }
        else { $newLines += $l }
    } else {
        if ($l -match "^current_step:" -and $stepDone) {
            $next = @{ implement="verify"; verify="review"; review="close"; close="done" }[$Step]
            $newLines += "current_step: $next"
        } else {
            $newLines += $l
        }
    }
}

Set-Content -Path $stateFile -Value ($newLines -join "`n") -NoNewline
Write-Output "[STATE] Step $Step complete. Proof: $actualSHA"
exit 0
