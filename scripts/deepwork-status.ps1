# deepwork-status.ps1
# Poll bead status for a deepwork plan. Reconcile results when all workers complete.
# Usage: .\deepwork-status.ps1 -PlanId "dw-20260602-041500" [-ProjectDir "D:\proj"]
param(
    [string]$PlanId = "",
    [string]$ProjectDir = "",
    [switch]$Watch
)
$ErrorActionPreference = "SilentlyContinue"
$configDir = $env:USERPROFILE + "\.config\opencode"
$scriptsDir = "$configDir\scripts"
$memoryDir = "$configDir\memory"
$hiveDir = "$memoryDir\hive\active"

if (-not $PlanId) {
    Write-Host "[deepwork-status] Usage: deepwork-status.ps1 -PlanId dw-YYYYMMDD-HHMMSS"
    exit 1
}

$workspaceDir = if ($ProjectDir) { "$ProjectDir\.opencode\deepwork" } else { "$configDir\deepwork" }
$planFile = Join-Path $workspaceDir "$PlanId.plan.md"
$beadsDir = Join-Path $workspaceDir "$PlanId.beads"

if (-not (Test-Path $planFile)) {
    Write-Host "[deepwork-status] Plan not found: $planFile"
    exit 1
}

function Get-PlanStatus {
    $content = Get-Content $planFile -Raw -Encoding UTF8
    $status = "UNKNOWN"
    if ($content -match '(?mi)^\*\*Status\*\*:\s*(\w+)') {
        $status = $matches[1].Trim()
    }
    $taskCount = 0
    $completeCount = 0
    $beadIds = @()
    if ($content -match '(?mi)^\|?\s*-?\s*\[\s*x\s*\]\s*(\S+?):') {
        # checked task
        $completeCount = [regex]::Matches($content, '(?mi)^\|?\s*-?\s*\[\s*x\s*\]\s*(\S+?):').Count
    }
    $taskRows = [regex]::Matches($content, '(?mi)^\|?\s*-?\s*\[\s*[x\s]*\]\s*(\S+?):')
    $taskCount = $taskRows.Count
    return @{ status = $status; taskCount = $taskCount; completeCount = $completeCount; content = $content }
}

function Show-Status {
    $p = Get-PlanStatus
    $beadIds = [regex]::Matches($p.content, '([a-z]+-\d{8}-\d{6}-\w)') | ForEach-Object { $_.Value } | Select-Object -Unique

    Write-Host "=== DeepWork: $PlanId ===" -ForegroundColor Cyan
    Write-Host "Status: $($p.status) | Tasks: $($p.completeCount)/$($p.taskCount) | Beads: $($beadIds.Count)"
    Write-Host ""

    foreach ($bid in $beadIds) {
        $beadFile = "$hiveDir\$bid.json"
        if (Test-Path $beadFile) {
            $bead = Get-Content $beadFile -Raw | ConvertFrom-Json
            $color = switch ($bead.status) {
                "completed" { "Green" }
                "in_progress" { "Yellow" }
                "blocked" { "Red" }
                default { "DarkGray" }
            }
            Write-Host "  [$bid] $($bead.status.ToUpper())" -ForegroundColor $color -NoNewline
            if ($bead.agent) { Write-Host " ($($bead.agent))" -ForegroundColor DarkGray -NoNewline }
            if ($bead.title) { Write-Host " - $($bead.title)" -ForegroundColor White }
            else { Write-Host "" }
            if ($bead.reason) { Write-Host "    → $($bead.reason)" -ForegroundColor DarkGray }
        } else {
            Write-Host "  [$bid] NOT FOUND in hive" -ForegroundColor DarkGray
        }
    }

    if ($p.status -eq "IN_PROGRESS" -and $p.completeCount -ge $p.taskCount -and $p.taskCount -gt 0) {
        Write-Host ""
        Write-Host "All tasks complete. Run reconciliation..." -ForegroundColor Green
        Write-Host "  deepwork-reconcile.ps1 -PlanId $PlanId [-ProjectDir '...']"
    }
}

if ($Watch) {
    Write-Host "[deepwork-status] Watching $PlanId (Ctrl+C to stop)" -ForegroundColor Yellow
    while ($true) {
        Clear-Host
        Show-Status
        Start-Sleep -Seconds 10
    }
} else {
    Show-Status
}

exit 0