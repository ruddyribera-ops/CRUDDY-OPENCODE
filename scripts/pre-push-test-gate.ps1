# pre-push-test-gate.ps1
# Git pre-push hook: runs tests before push to main/master.
# Blocks push if any test suite fails.
#
# === INSTALL ===
# Install in any project (one-time per repo):
#
#   Option A - use the install helper (recommended):
#     pwsh -NoProfile -File "$env:USERPROFILE\.config\opencode\scripts\install-pre-push-gate.ps1" -ProjectPath "C:\path\to\repo"
#
#   Option B - copy manually:
#     cp "$env:USERPROFILE\.config\opencode\scripts\pre-push-test-gate.ps1" "C:\path\to\repo\.git\hooks\pre-push.ps1"
#     # then create a tiny .git/hooks/pre-push wrapper (cmd) that calls pwsh
#     # OR rely on Windows file association for .ps1 (see install helper)
#
#   Option C - global hooks (all repos):
#     git config --global core.hooksPath "$env:USERPROFILE\.config\opencode\git-hooks"
#     cp "$env:USERPROFILE\.config\opencode\scripts\pre-push-test-gate.ps1" "$env:USERPROFILE\.config\opencode\git-hooks\pre-push"
#
# === UNINSTALL ===
#   Remove-Item ".git/hooks/pre-push*" -Force
#
# === BEHAVIOR ===
#   - Pushes to main/master: runs detected tests, blocks on failure.
#   - Pushes to other branches: skipped (dev workflow stays fast).
#   - No test framework detected: warns but allows push.
#   - All test output is logged to: $env:USERPROFILE\.config\opencode\memory\gate-system.log

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$Remote = "origin",
    [string]$Url = ""
)

$ErrorActionPreference = "Continue"

# --- Config -------------------------------------------------------------------
$logFile = Join-Path $env:USERPROFILE ".config\opencode\memory\gate-system.log"
$logDir  = Split-Path -Parent $logFile
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# --- Logging ------------------------------------------------------------------
function Write-GateLog {
    param([string]$Message)
    $line = "[pre-push-gate] $(Get-Date -Format 'HH:mm:ss') $Message"
    try {
        Add-Content -LiteralPath $logFile -Value $line -ErrorAction SilentlyContinue
    } catch {
        # never let logging break the hook
    }
    return $line
}

# --- Determine which PowerShell to use for spawning tests ---------------------
# We re-spawn tests in a fresh pwsh so npm/pytest child-process state
# (node_modules .bin on PATH, venv activation, etc.) starts clean and
# matches what CI / developers see on their machines.
$testRunner = $null
if (Get-Command -Name pwsh -ErrorAction SilentlyContinue) {
    $testRunner = "pwsh"
} elseif (Get-Command -Name powershell -ErrorAction SilentlyContinue) {
    $testRunner = "powershell"
} else {
    Write-Host "[pre-push-gate] ERROR: no PowerShell executable found on PATH" -ForegroundColor Red
    Write-GateLog "ERROR no-pwsh"
    exit 1
}

# --- Read ref being pushed ----------------------------------------------------
# Git passes one line per ref: <local-ref> <local-sha> <remote-ref> <remote-sha>
$stdin = @($input)
if ($stdin.Count -lt 1 -or [string]::IsNullOrWhiteSpace($stdin[0])) {
    Write-GateLog "SKIP no-stdin"
    exit 0
}

$parts     = $stdin[0] -split " "
$localRef  = $parts[0]
$remoteRef = $parts[2]

Write-GateLog "PUSH_ATTEMPT $localRef -> $remoteRef"

# --- Branch gate --------------------------------------------------------------
$branch = ($localRef -replace "^refs/heads/", "").Trim()
if ($branch -ne "main" -and $branch -ne "master") {
    Write-GateLog "SKIP branch=$branch"
    exit 0
}

# --- Detect test frameworks ---------------------------------------------------
$projectRoot = (Get-Location).Path
$tests       = New-Object System.Collections.Generic.List[object]

# Node: package.json with test script
$pkgPath = Join-Path $projectRoot "package.json"
if (Test-Path -LiteralPath $pkgPath) {
    try {
        $pkg = Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json
        if ($pkg.scripts -and $pkg.scripts.PSObject.Properties.Name -contains "test") {
            $tests.Add(@{ name = "npm test"; cmd = "npm test" }) | Out-Null
        }
    } catch {
        Write-GateLog "WARN package.json-parse-failed: $($_.Exception.Message)"
    }

    # Playwright (Node) — only add if npm test is also there or this is the only suite
    $pwJs = Join-Path $projectRoot "playwright.config.js"
    $pwTs = Join-Path $projectRoot "playwright.config.ts"
    if ((Test-Path -LiteralPath $pwJs) -or (Test-Path -LiteralPath $pwTs)) {
        $tests.Add(@{ name = "playwright"; cmd = "npx playwright test" }) | Out-Null
    }
}

# Python: pytest
$pytestIni  = Join-Path $projectRoot "pytest.ini"
$pyproject  = Join-Path $projectRoot "pyproject.toml"
if ((Test-Path -LiteralPath $pytestIni) -or (Test-Path -LiteralPath $pyproject)) {
    # Only add pytest if config actually references pytest (avoid pyproject.toml for poetry only)
    $hasPytestConfig = $false
    if (Test-Path -LiteralPath $pytestIni) {
        $hasPytestConfig = $true
    } elseif (Test-Path -LiteralPath $pyproject) {
        $toml = Get-Content -LiteralPath $pyproject -Raw
        if ($toml -match '(?im)^\s*\[tool\.pytest[._]?ini[._]?options\]') {
            $hasPytestConfig = $true
        }
    }
    if ($hasPytestConfig) {
        $tests.Add(@{ name = "pytest"; cmd = "pytest" }) | Out-Null
    }
}

# --- Decide -------------------------------------------------------------------
if ($tests.Count -eq 0) {
    Write-Host ""
    Write-Host "[pre-push-gate] WARNING: no test framework detected in $projectRoot" -ForegroundColor Yellow
    Write-Host "[pre-push-gate] Push to $branch is ALLOWED (no gate)." -ForegroundColor Yellow
    Write-Host ""
    Write-GateLog "WARN no-test-framework project=$projectRoot"
    exit 0
}

Write-Host ""
Write-Host "[pre-push-gate] Branch $branch is gated. Detected suites: $($tests.name -join ', ')" -ForegroundColor Cyan
Write-Host ""

# --- Run tests ----------------------------------------------------------------
$failed = 0
$total  = $tests.Count
$idx    = 0

foreach ($t in $tests) {
    $idx++
    Write-Host "================================================================" -ForegroundColor DarkGray
    Write-Host "[pre-push-gate] ($idx/$total) Running: $($t.name)" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor DarkGray
    Write-GateLog "TEST_START $($t.name)"

    $startTime = Get-Date
    try {
        & $testRunner -NoProfile -Command $t.cmd
        $exitCode = $LASTEXITCODE
    } catch {
        Write-Host "[pre-push-gate] EXCEPTION running $($t.name): $($_.Exception.Message)" -ForegroundColor Red
        Write-GateLog "TEST_ERROR $($t.name) $($_.Exception.Message)"
        $failed++
        continue
    }
    $elapsed = (Get-Date) - $startTime

    if ($exitCode -ne 0) {
        Write-Host ""
        Write-Host "[pre-push-gate] FAILED: $($t.name) (exit=$exitCode, took $($elapsed.ToString('mm\:ss')))" -ForegroundColor Red
        Write-GateLog "TEST_FAIL $($t.name) exit=$exitCode elapsed_sec=$([int]$elapsed.TotalSeconds)"
        $failed++
    } else {
        Write-Host ""
        Write-Host "[pre-push-gate] PASSED: $($t.name) (took $($elapsed.ToString('mm\:ss')))" -ForegroundColor Green
        Write-GateLog "TEST_PASS $($t.name) elapsed_sec=$([int]$elapsed.TotalSeconds)"
    }
}

# --- Verdict ------------------------------------------------------------------
Write-Host ""
if ($failed -gt 0) {
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "[pre-push-gate] PUSH BLOCKED: $failed of $total test suite(s) failed" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "Fix the failing tests, then re-run: git push" -ForegroundColor Yellow
    Write-GateLog "PUSH_BLOCKED failed=$failed total=$total"
    exit 1
}

Write-Host "================================================================" -ForegroundColor Green
Write-Host "[pre-push-gate] All tests passed. Push to $branch ALLOWED." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-GateLog "PUSH_ALLOWED suites=$total"
exit 0
