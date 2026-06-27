# retro-analyze.ps1
# Evolution trigger — invoked by memory-bridge every 10 tasks.
# Scans session_log.md for repetition patterns and proposes new genes.
#
# Usage: powershell -File retro-analyze.ps1 -TaskCount <N> [-WriteGenes]
#
# Exit codes:
#   0 = no new genes needed
#   1 = error
#   2 = genes auto-written (caller should notify evolution-agent)

param(
    [Parameter(Mandatory=$true)]
    [int]$TaskCount,

    [switch]$WriteGenes
)

$configDir = "$env:USERPROFILE\.config\opencode"
$memoryDir = "$configDir\memory"
$sessionLog = Join-Path $memoryDir "session_log.md"
$outcomesDir = Join-Path $memoryDir "outcomes"
$patternsFile = Join-Path $outcomesDir "patterns.jsonl"
$logFile = Join-Path $memoryDir "gate-system.log"

function Log-Retro($msg) {
    $line = "[retro-analyze] $(Get-Date -Format 'HH:mm:ss') $msg"
    try {
        Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    } catch {}
}

Log-Retro "START taskCount=$TaskCount writeGenes=$WriteGenes"

# Check if session log exists
if (-not (Test-Path $sessionLog)) {
    Log-Retro "SKIP — no session_log.md found"
    Write-Host "[retro-analyze] No session log to analyze" -ForegroundColor Yellow
    exit 0
}

# Read recent task entries
$logContent = Get-Content $sessionLog -Tail ($TaskCount * 3) -ErrorAction SilentlyContinue
if (-not $logContent) {
    Log-Retro "SKIP — session log empty"
    exit 0
}

# Count task types in recent history
$taskTypes = @{}
$agentTypes = @{}
$blockPatterns = @{}

foreach ($line in $logContent) {
    # Match task lines like "  - [timestamp] task: X | agent: Y | result: Z"
    if ($line -match "agent:\s*(\S+)") {
        $agent = $Matches[1]
        $agentTypes[$agent] = ($agentTypes[$agent] + 1)
    }
    if ($line -match "result:\s*FAIL|BLOCKED") {
        $blockPatterns[$agent] = ($blockPatterns[$agent] + 1)
    }
}

# Detect repetition: agent with > 50% failure rate
$proposedGenes = @()
foreach ($agent in $agentTypes.Keys) {
    $total = $agentTypes[$agent]
    $fails = if ($blockPatterns.ContainsKey($agent)) { $blockPatterns[$agent] } else { 0 }
    if ($total -ge 3 -and $fails -ge ($total / 2)) {
        $proposedGenes += @{
            id = "AUTO-$agent-$(Get-Date -Format 'MMdd')"
            name = "$agent high failure rate"
            description = "Agent $agent failed $fails of $total tasks in last $TaskCount. Investigate root cause."
            triggers = @($agent.ToLower())
        }
    }
}

Log-Retro "ANALYZED agents=$($agentTypes.Count) proposed_genes=$($proposedGenes.Count)"

if ($proposedGenes.Count -eq 0) {
    Write-Host "[retro-analyze] Analyzed $TaskCount tasks — no new genes needed" -ForegroundColor Green
    exit 0
}

Write-Host "[retro-analyze] Detected $($proposedGenes.Count) potential gene(s):" -ForegroundColor Yellow
foreach ($g in $proposedGenes) {
    Write-Host "  - $($g.id): $($g.name)" -ForegroundColor Yellow
}

if ($WriteGenes) {
    # Write to a pending genes file for evolution-agent review
    $pendingFile = Join-Path $outcomesDir "pending-genes.jsonl"
    if (-not (Test-Path $outcomesDir)) {
        New-Item -ItemType Directory -Path $outcomesDir -Force | Out-Null
    }
    foreach ($g in $proposedGenes) {
        $g | ConvertTo-Json -Compress | Add-Content -Path $pendingFile
    }
    Log-Retro "WROTE $($proposedGenes.Count) pending genes to $pendingFile"
    Write-Host "[GENES WRITTEN] $($proposedGenes.Count) genes added to pending-genes.jsonl" -ForegroundColor Cyan
    Write-Host "Next: route to @evolution-agent for review/approval" -ForegroundColor Cyan
    exit 2
}

# Without -WriteGenes, just report findings
exit 0
