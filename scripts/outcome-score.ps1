# outcome-score.ps1 - Computes pattern maturity scores from patterns.jsonl
# Usage: .\outcome-score.ps1                    # compute all scores
#        .\outcome-score.ps1 -TaskType "auth"    # compute for specific type
# Output: pattern_maturity.yaml

param(
    [Parameter(Mandatory=$false)]
    [string]$TaskType = "",

    [Parameter(Mandatory=$false)]
    [int]$MinSamples = 2  # min outcomes needed before scoring
)

$CONFIG_ROOT = $env:OPENCODE_CONFIG_HOME
if (-not $CONFIG_ROOT) {
    if ($env:USERPROFILE) { $CONFIG_ROOT = Join-Path $env:USERPROFILE ".config\opencode" }
    else { throw "OPENCODE_CONFIG_HOME and USERPROFILE are both unset - cannot determine config root" }
}

$ErrorActionPreference = "Stop"

$OUTCOMES_DIR = Join-Path $CONFIG_ROOT "memory\outcomes"
$PATTERNS_FILE = Join-Path $OUTCOMES_DIR "patterns.jsonl"
$MATURITY_FILE = Join-Path $OUTCOMES_DIR "pattern_maturity.yaml"

if (-not (Test-Path $PATTERNS_FILE)) {
    Write-Output "NO_PATTERNS:no outcomes recorded yet"
    exit 0
}

# Load all outcomes
$lines = [System.IO.File]::ReadAllLines($PATTERNS_FILE, [System.Text.Encoding]::UTF8)
$outcomes = @()
foreach ($line in $lines) {
    if ($line -ne "") {
        try { $outcomes += $line | ConvertFrom-Json } catch {}
    }
}

if ($outcomes.Count -eq 0) {
    Write-Output "NO_PATTERNS:no valid outcomes found"
    exit 0
}

# Group by task_type
$grouped = @{}
foreach ($o in $outcomes) {
    $tt = $o.task_type
    if (-not $grouped.ContainsKey($tt)) { $grouped[$tt] = @() }
    $grouped[$tt] += $o
}

function Compute-Score {
    param($samples)
    $count = $samples.Count
    $successes = ($samples | Where-Object { $_.success }).Count
    $successRate = $successes / $count

    $medianDuration = ($samples | ForEach-Object { $_.duration_seconds } | Sort-Object | Select-Object -First ([math]::Ceiling($count / 2)))[0]
    if ($medianDuration -eq 0) { $medianDuration = 1 }

    $avgDuration = ($samples | Measure-Object -Property duration_seconds -Average).Average
    $speedFactor = [math]::Min(2.0, $medianDuration / [math]::Max(1, $avgDuration))

    $score = ($successRate * 0.7) + ($speedFactor * 0.3)

    $failures = $count - $successes
    $failureRate = $failures / $count

    # Determine maturity
    $maturity = "candidate"
    if ($score -gt 1.2) { $maturity = "proven" }
    if ($score -lt 0.5) { $maturity = "anti-pattern" }
    if ($failureRate -gt 0.6) { $maturity = "anti-pattern" }

    return @{
        count = $count
        successes = $successes
        failures = $failures
        success_rate = [math]::Round($successRate, 3)
        median_duration = $medianDuration
        speed_factor = [math]::Round($speedFactor, 3)
        score = [math]::Round($score, 3)
        maturity = $maturity
        last_updated = (Get-Date).ToUniversalTime().ToString("o")
    }
}

# Compute scores
$maturityData = @{
    generated = (Get-Date).ToUniversalTime().ToString("o")
    patterns = @{}
}

$types = if ($TaskType -ne "") { @($TaskType) } else { $grouped.Keys }

foreach ($tt in $types) {
    $samples = $grouped[$tt]
    if ($null -eq $samples -or $samples.Count -lt $MinSamples) { continue }

    $scores = Compute-Score $samples
    $maturityData.patterns[$tt] = @{
        score = $scores.score
        maturity = $scores.maturity
        successes = $scores.successes
        failures = $scores.failures
        total = $scores.count
        success_rate = $scores.success_rate
        median_duration_s = $scores.median_duration
        speed_factor = $scores.speed_factor
        last_updated = $scores.last_updated
    }
}

# Write YAML output
$yamlLines = @("# Pattern maturity scores - auto-generated")
$yamlLines += "generated: $($maturityData.generated)"
$yamlLines += "patterns:"
foreach ($tt in $maturityData.patterns.Keys | Sort-Object) {
    $p = $maturityData.patterns[$tt]
    $yamlLines += "  $tt`:"
    $yamlLines += "    score: $($p.score)"
    $yamlLines += "    maturity: $($p.maturity)"
    $yamlLines += "    successes: $($p.successes)"
    $yamlLines += "    failures: $($p.failures)"
    $yamlLines += "    total: $($p.total)"
    $yamlLines += "    success_rate: $($p.success_rate)"
    $yamlLines += "    median_duration_s: $($p.median_duration)"
    $yamlLines += "    speed_factor: $($p.speed_factor)"
    $yamlLines += "    last_updated: $($p.last_updated)"
}

[System.IO.File]::WriteAllLines($MATURITY_FILE, $yamlLines, [System.Text.Encoding]::UTF8)

$count = $maturityData.patterns.Keys.Count
Write-Output "SCORED:$count patterns|MATURITY_FILE updated"
exit 0