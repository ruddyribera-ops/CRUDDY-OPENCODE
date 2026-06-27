# record-good-deploy.ps1
# Record a successful deploy SHA so deploy-rollback.ps1 can roll back to it later.
# Usage:
#   .\record-good-deploy.ps1                  # record current HEAD
#   .\record-good-deploy.ps1 -Sha <sha>       # record a specific SHA

param(
    [string]$Sha = ""
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

function Log-Deploy($msg) {
    $line = "[record-good-deploy] $(Get-Date -Format 'HH:mm:ss') $msg"
    Write-Host $line
    # Silently swallow log-write errors so logging never breaks the record flow.
    try { Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue } catch {}
}

# Resolve SHA: explicit param wins, otherwise use current HEAD
if ($Sha) {
    $targetSha = $Sha.Trim()
} else {
    $targetSha = (git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) {
        Log-Deploy "FAIL git rev-parse HEAD failed; not inside a git repo?"
        exit 1
    }
}

# Validate SHA format (7-40 hex chars) so we never write garbage
if ($targetSha -notmatch '^[0-9a-fA-F]{7,40}$') {
    Log-Deploy "FAIL SHA '$targetSha' is not a valid git SHA"
    exit 1
}

# Read existing entries (if any), excluding the one we're about to add (dedupe + move-to-front)
$existing = @()
if (Test-Path $lastGoodFile) {
    $existing = Get-Content $lastGoodFile | Where-Object { $_.Trim() -ne "" -and $_.Trim() -ne $targetSha }
}

# Prepend new SHA so the file stays "most recent first" (deploy-rollback reads First 1)
$newContent = @($targetSha) + $existing

try {
    Set-Content -Path $lastGoodFile -Value $newContent -ErrorAction Stop
} catch {
    Log-Deploy "FAIL could not write $lastGoodFile : $($_.Exception.Message)"
    exit 1
}

Log-Deploy "RECORDED sha=$targetSha total_known=$($newContent.Count)"
exit 0
