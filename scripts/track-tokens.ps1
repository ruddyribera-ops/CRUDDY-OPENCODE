# track-tokens.ps1 — Token budget tracker for OpenCode agents
# Usage: track-tokens.ps1 -Action check -Agent <name> -Tokens <N>
#        track-tokens.ps1 -Action record -Agent <name> -Tokens <N> -Task<name>
#        track-tokens.ps1 -Action summary

param(
    [ValidateSet("check", "record", "summary", "reset")]
    [string]$Action = "check",

    [string]$Agent = "",
    [int]$Tokens = 0,
    [string]$Task = "",
    [string]$Workdir = "C:\Users\Windows\.config\opencode"
)

$DbPath = Join-Path $Workdir "memory\token-tracking.jsonl"
$BudgetPath = Join-Path $Workdir "memory\token-budgets.yaml"

function Ensure-Db {
    $dir = Split-Path $DbPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Load-Budgets {
    if (Test-Path $BudgetPath) {
        $content = Get-Content $BudgetPath -Raw
        if ($content.Trim()) {
            return $content | ConvertFrom-Yaml
        }
    }
    return @{}
}

function Save-Record {
    param([int]$Tokens, [string]$Agent, [string]$Task)
    Ensure-Db
    $entry = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        agent = $Agent
        tokens = $Tokens
        task = $Task
    } | ConvertTo-Json -Compress
    Add-Content -Path $DbPath -Value $entry
}

function Check-Budget {
    param([string]$Agent, [int]$Tokens)
    $budgets = Load-Budgets
    $limit = $budgets.agent_budgets.$Agent
    if (-not $limit) {
        $limit = $budgets.default_per_task
 if (-not $limit) { $limit = 50000 }
    }
    if ($Tokens -gt $limit) {
        Write-Host "REJECT: $Agent exceeds budget ($Tokens > $limit)"
        exit 1
    }
    Write-Host "GO: $Agent within budget ($Tokens <= $limit)"
    exit 0
}

function Get-Summary {
    Ensure-Db
    if (-not (Test-Path $DbPath)) {
        Write-Host "No token records found."
        return
    }
    $records = Get-Content $DbPath | ForEach-Object { $_ | ConvertFrom-Json }
    $total = ($records | Measure-Object -Property tokens -Sum).Sum
    $byAgent = $records | Group-Object agent | ForEach-Object {
        @{ name = $_.Name; tokens = ($_.Group | Measure-Object -Property tokens -Sum).Sum; count = $_.Count }
    }
    Write-Host "=== Token Summary ==="
    Write-Host "Total: $total tokens across $($records.Count) tasks"
    Write-Host ""
    $byAgent | ForEach-Object {
        Write-Host "$($_.name): $($_.tokens) tokens ($($_.count) tasks)"
    }
}

switch ($Action) {
    "check" { Check-Budget -Agent $Agent -Tokens $Tokens }
    "record" { Save-Record -Tokens $Tokens -Agent $Agent -Task $Task }
    "summary" { Get-Summary }
    "reset" {
        if (Test-Path $DbPath) { Remove-Item $DbPath -Force }
        Write-Host "Token database reset."
    }
}
