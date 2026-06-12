# deploy-rollback.ps1
# Auto-rollback to last known good SHA when deploy fails.
# Usage:
#   .\deploy-rollback.ps1                              # auto-rollback to last good SHA
#   .\deploy-rollback.ps1 -ToSha <sha>                 # roll back to a specific SHA
#   .\deploy-rollback.ps1 -List                        # show recent known-good SHAs
#   .\deploy-rollback.ps1 -DeployUrl https://app.com   # verify with health check after push

param(
    [string]$ToSha = "",
    [switch]$List,
    [string]$DeployUrl = "",
    [string]$HealthPath = "/api/health"
)

$ErrorActionPreference = "Stop"

$configDir = "$env:USERPROFILE\.config\opencode"
$memoryDir = "$configDir\memory"
$factoryDir = "$memoryDir\factory"
$lastGoodFile = "$factoryDir\last_good_sha.txt"
$logFile = "$memoryDir\gate-system.log"

# Ensure directories exist (first-run safety)
if (-not (Test-Path $factoryDir)) {
    New-Item -ItemType Directory -Path $factoryDir -Force | Out-Null
}
if (-not (Test-Path $memoryDir)) {
    New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null
}

function Log-Rollback($msg) {
    $line = "[deploy-rollback] $(Get-Date -Format 'HH:mm:ss') $msg"
    Write-Host $line
    # Silently swallow log-write errors so logging never breaks the rollback flow.
    try { Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue } catch {}
}

# List mode (pure file read, no git required so it works from any directory)
if ($List) {
    if (Test-Path $lastGoodFile) {
        $entries = Get-Content $lastGoodFile | Where-Object { $_.Trim() -ne "" }
        if ($entries.Count -gt 0) {
            Write-Host "Known good deploys (most recent first):"
            $entries | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host "No known good deploys recorded yet."
        }
    } else {
        Write-Host "No known good deploys recorded yet."
    }
    exit 0
}

# Verify we are inside a git working tree before doing anything destructive.
try {
    git rev-parse --is-inside-work-tree 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log-Rollback "FAIL not inside a git working tree; aborting"
        exit 1
    }
} catch {
    Log-Rollback "FAIL git not available: $($_.Exception.Message)"
    exit 1
}

# Determine target SHA
if ($ToSha) {
    $targetSha = $ToSha.Trim()
    Log-Rollback "MANUAL_ROLLBACK target=$targetSha"
} elseif (Test-Path $lastGoodFile) {
    $firstLine = (Get-Content $lastGoodFile -First 1)
    if ($firstLine) { $targetSha = $firstLine.Trim() }
    if (-not $targetSha) {
        Log-Rollback "FAIL last_good file is empty at $lastGoodFile; manual intervention required"
        exit 1
    }
    Log-Rollback "AUTO_ROLLBACK target=$targetSha"
} else {
    Log-Rollback "FAIL no known good SHA file at $lastGoodFile; manual intervention required"
    exit 1
}

# Sanity-check target SHA looks like a SHA (7-40 hex chars) so we don't pass garbage to git.
if ($targetSha -notmatch '^[0-9a-fA-F]{7,40}$') {
    Log-Rollback "FAIL target SHA '$targetSha' is not a valid git SHA"
    exit 1
}

# Get current (bad) SHA
$currentSha = git rev-parse HEAD
if ($LASTEXITCODE -ne 0) {
    Log-Rollback "FAIL git rev-parse HEAD failed with exit=$LASTEXITCODE"
    exit 1
}
$currentSha = $currentSha.Trim()

if ($currentSha -eq $targetSha) {
    Log-Rollback "SKIP current SHA=$currentSha already matches target; nothing to do"
    exit 0
}

Log-Rollback "REVERT current=$currentSha target=$targetSha"

# Run git revert
try {
    $revertOutput = git revert $currentSha --no-edit 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log-Rollback "FAIL git revert exit=$LASTEXITCODE output=$($revertOutput -join ' | ')"
        exit 1
    }
} catch {
    Log-Rollback "FAIL git revert exception: $($_.Exception.Message)"
    exit 1
}

# Push the revert
try {
    $pushOutput = git push 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log-Rollback "FAIL git push exit=$LASTEXITCODE output=$($pushOutput -join ' | ')"
        exit 1
    }
    Log-Rollback "PUSHED revert commit to origin"
} catch {
    Log-Rollback "FAIL git push exception: $($_.Exception.Message)"
    exit 1
}

# Optional: verify health endpoint
if ($DeployUrl) {
    $healthUrl = "$DeployUrl$HealthPath"
    Log-Rollback "VERIFY health check $healthUrl"
    try {
        $health = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 30 -UseBasicParsing
        if ($health.StatusCode -eq 200) {
            Log-Rollback "VERIFY_OK health 200"
        } else {
            Log-Rollback "VERIFY_FAIL health=$($health.StatusCode)"
        }
    } catch {
        Log-Rollback "VERIFY_FAIL exception: $($_.Exception.Message)"
    }
}

Log-Rollback "ROLLBACK_COMPLETE to=$targetSha"
exit 0
