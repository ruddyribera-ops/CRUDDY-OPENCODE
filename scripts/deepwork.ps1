# deepwork.ps1
param(
    [string]$Goal = "",
    [string]$ProjectDir = "",
    [int]$MaxWorkers = 3
)
$ErrorActionPreference = "SilentlyContinue"
$configDir = $env:USERPROFILE + "\.config\opencode"
$scriptsDir = "$configDir\scripts"
$memoryDir = "$configDir\memory"
$hiveDir = "$memoryDir\hive\active"

if (-not $Goal) {
    Write-Host "[deepwork] Usage: deepwork.ps1 -Goal 'Add OAuth login' [-ProjectDir 'D:\proj']"
    exit 1
}

if ($ProjectDir -and (Test-Path $ProjectDir)) {
    Push-Location $ProjectDir
}

$workspaceDir = if ($ProjectDir) { "$ProjectDir\.opencode\deepwork" } else { "$configDir\deepwork" }
New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$planId = "dw-$ts"
$planFile = Join-Path $workspaceDir "$planId.plan.md"
$beadsDir = Join-Path $workspaceDir "$planId.beads"
New-Item -ItemType Directory -Path $beadsDir -Force | Out-Null

$planLines = @()
$planLines += "# DeepWork Plan: $Goal"
$planLines += "**Plan ID:** $planId"
$planLines += "**Created:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$planLines += "**Status:** PLANNING"
$planLines += ""
$planLines += "## Goal"
$planLines += "$Goal"
$planLines += ""
$planLines += "## Tasks"
$planLines += "<!-- Coordinator will fill this in -->"
$planLines += ""
$planLines += "## Progress"
$planLines += "<!-- 0/0 tasks complete -->"
[System.IO.File]::WriteAllLines($planFile, $planLines, [System.Text.Encoding]::UTF8)

$kwRaw = [regex]::Matches($Goal, '(?<![a-z])([A-Z][a-z]+|[a-z]{4,})') | ForEach-Object { $_.Value.ToLower() }
$keywords = $kwRaw | Where-Object { $_ -notmatch '^(the|add|build|fix|implement|create|and|or|with|for|to)$' } | Select-Object -First 8
$kwStr = $keywords -join ", "

$coordBeadId = "$planId-c"
& "$scriptsDir\beads.ps1" create -Title "COORDINATOR: $Goal" -Type "coordination" -HiveDir $hiveDir | Out-Null

$coordFile = Join-Path $beadsDir "COORDINATOR.md"
$coordLines = @()
$coordLines += "# Coordinator Instructions for: $Goal"
$coordLines += ""
$coordLines += "## Plan ID: $planId"
$coordLines += "## Plan File: $planFile"
$coordLines += ""
$coordLines += "## Your Job"
$coordLines += "1. Read the goal: $Goal"
$coordLines += "2. Break it into 2-$MaxWorkers parallelizable subtasks"
$coordLines += "3. For each subtask:"
$coordLines += "   - Create a bead: beads.ps1 create -Title SUBTASK_NAME -Type implementation"
$coordLines += "   - Write the task spec to the bead file"
$coordLines += "4. Update the plan file with task list and bead IDs"
$coordLines += "5. Report when all subtasks are spawned"
$coordLines += ""
$coordLines += "## Subtask Keywords Detected"
$coordLines += "$kwStr"
$coordLines += ""
$coordLines += "## Important"
$coordLines += "- Each subtask should be independently verifiable (has a test or verification command)"
$coordLines += "- Maximum $MaxWorkers workers in parallel"
$coordLines += "- Write bead files to: $beadsDir"
$coordLines += ""
$coordLines += "## Output Format"
$coordLines += "After decomposition, write to the plan file:"
$coordLines += "- Task list with bead IDs"
$coordLines += "- Mark status: IN_PROGRESS"
$coordLines += ""
$coordLines += "Then create beads and signal completion."
[System.IO.File]::WriteAllLines($coordFile, $coordLines, [System.Text.Encoding]::UTF8)

Write-Host "[deepwork] Plan created: $planId" -ForegroundColor Cyan
Write-Host "  Plan file: $planFile"
Write-Host "  Beads dir: $beadsDir"
Write-Host "  Coordinator: $coordFile"
Write-Host ""
Write-Host "Next: Run deepwork-status.ps1 -PlanId $planId [-ProjectDir '...'] [-Watch]" -ForegroundColor Yellow

if ($ProjectDir) { Pop-Location }
exit 0