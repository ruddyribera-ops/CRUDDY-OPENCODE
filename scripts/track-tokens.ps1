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
    [string]$Workdir = ""
)

if (-not $Workdir) {
    $Workdir = $env:OPENCODE_CONFIG_HOME
    if (-not $Workdir) {
        if ($env:USERPROFILE) { $Workdir = Join-Path $env:USERPROFILE ".config\opencode" }
        else { throw "OPENCODE_CONFIG_HOME and USERPROFILE are both unset - cannot determine workdir" }
    }
}

$DbPath = Join-Path $Workdir "memory\token-tracking.jsonl"
$BudgetPath = Join-Path $Workdir "memory\token-budgets.yaml"

function Ensure-Db {
    $dir = Split-Path $DbPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Load-Budgets {
    # Try powershell-yaml first; fall back to hardcoded values on any failure.
    # This works on PowerShell 5.1 where ConvertFrom-Yaml is not native.
    try {
        if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
            Import-Module powershell-yaml -ErrorAction Stop
        }
        if (Test-Path $BudgetPath) {
            $content = Get-Content $BudgetPath -Raw
            if ($content.Trim()) {
                return $content | ConvertFrom-Yaml
            }
        }
    } catch {
        # YAML unavailable or parse failure — use hardcoded fallback below
        Write-Verbose "YAML budget load failed, using hardcoded fallback: $_"
    }
    # Hardcoded fallback when YAML parser unavailable or config missing
    return [PSCustomObject]@{
        agent_budgets = @{
            'main-coordinator'     = 80000
            'code-builder'         = 50000
            'code-analyzer'         = 30000
            'bug-fixer'            = 40000
            'architecture-advisor' = 40000
            'project-manager'     = 30000
            'tech-lead'           = 50000
            'qa-engineer'          = 30000
            'designer'             = 40000
            'code-reviewer'        = 30000
            'cybersecurity'        = 40000
            'expert-tester'        = 40000
            'ai-evaluator'         = 40000
            'observability-sre'    = 40000
            'tech-writer'          = 30000
            'skill-manager'        = 30000
        }
    }
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

    # Per-session budget check
    $limit = $budgets.agent_budgets.$Agent
    if (-not $limit) {
        Write-Warning "Unknown agent '$Agent' - using default budget 50000. Add to token-budgets.yaml or hardcoded map."
        $limit = $budgets.default_per_task
        if (-not $limit) { $limit = 50000 }
    }
    if ($Tokens -gt $limit) {
        Write-Host "REJECT: $Agent per-session budget exceeded ($Tokens > $limit)"
        exit 1
    }

    # Per-task budget check (if defined in budgets.yaml per_task section)
    if ($budgets.per_task) {
        $perTaskLimit = $budgets.per_task.$Agent
        if ($perTaskLimit) {
            if ($Tokens -gt $perTaskLimit) {
                Write-Host "REJECT: $Agent per-task budget exceeded ($Tokens > $perTaskLimit)"
                exit 1
            }
        }
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
