param(
    [string]$Action = "add",
    [string]$Agent = "",
    [int]$Tokens = 0,
    [string]$SessionYamlPath = "$env:USERPROFILE\.config\opencode\memory\session.yaml"
)

$ErrorActionPreference = "Stop"

$tokenFile = Join-Path (Split-Path $SessionYamlPath -Parent) "token_budget.yaml"

if ($Action -eq "reset") {
$default = @"
# Token Budget Tracking
# Budget: 500K tokens per session (DeepSeek), 100K per task max
session_tokens: 0
per_agent:
warnings: []
"@
    $default | Out-File -FilePath $tokenFile -Encoding UTF8
    Write-Host "OK token budget reset"
    return
}

if (-not (Test-Path $tokenFile)) {
    & $MyInvocation.MyCommand.Path -Action "reset"
    return
}

$content = Get-Content -Path $tokenFile -Raw
$content = $content -replace "`r`n", "`n"

if ($Action -eq "add") {
    $currentTotal = 0
    if ($content -match "session_tokens: (\d+)") { $currentTotal = [int]$matches[1] }
    $newTotal = $currentTotal + $Tokens

    # Use variable separator for agent: pattern to avoid drive letter parsing
    $agentKey = "${Agent}:"
    $agentPattern = [regex]::Escape("  ${Agent}:") + " \d+"
    if ($content -match $agentPattern) {
        $regex = [regex]::Escape("  ${Agent}:") + " (\d+)"
        if ($content -match $regex) {
            $agentCurrent = [int]$matches[1]
            $agentNew = $agentCurrent + $Tokens
            $content = $content -replace [regex]::Escape("  ${Agent}: $agentCurrent"), "  ${Agent}: $agentNew"
        }
    } else {
        $content = $content -replace "(per_agent:\n)", "`$1  ${Agent}: $Tokens`n"
    }

    $content = $content -replace "session_tokens: \d+", "session_tokens: $newTotal"

    $warnings = @()
    if ($newTotal -gt 400000) { $warnings += "CRITICAL: $newTotal tokens used (budget 500K)" }
    elseif ($newTotal -gt 300000) { $warnings += "WARNING: $newTotal tokens used (80% of budget)" }
    elseif ($newTotal -gt 200000) { $warnings += "NOTE: $newTotal tokens used (50% of budget)" }

    if ($warnings.Count -gt 0) {
        Write-Host "TOKEN WARNING: $($warnings[0])"
    }

    $content = $content -replace "`n", "`r`n"
    $content | Out-File -FilePath $tokenFile -Encoding UTF8
    Write-Host "OK tokens: +$Tokens (total: $newTotal)"
}
elseif ($Action -eq "report") {
    if ($content -match "session_tokens: (\d+)") {
        $total = [int]$matches[1]
        $pct = [math]::Round(($total / 500000) * 100, 1)
        Write-Host "Token report: $total / 500K ($pct%)"
        
        $lines = $content -split "`n"
        foreach ($line in $lines) {
            if ($line -match "^\s+([a-z-]+):\s+(\d+)") {
                $aPct = [math]::Round(([int]$matches[2] / 500000) * 100, 1)
                Write-Host "  $($matches[1]): $($matches[2]) ($aPct%)"
            }
        }
    } else {
        Write-Host "Token report: 0 / 500K (0%)"
    }
}
elseif ($Action -eq "check") {
    # Read budgets.yaml for limits
    $budgetsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "rules\budgets.yaml"
    if (-not (Test-Path $budgetsPath)) {
        Write-Host "BUDGETS_YAML_NOT_FOUND"
        exit 0  # Fail open — don't block if budgets.yaml missing
    }
    
    $budgetsContent = Get-Content -Path $budgetsPath -Raw
    
    # Extract per_session limit for this agent
    $perSessionLimit = $null
    if ($budgetsContent -match "${Agent}:\s+(\d+)") {
        $perSessionLimit = [int]$matches[1]
    } elseif ($budgetsContent -match "default:\s+(\d+)") {
        $perSessionLimit = [int]$matches[1]
    }
    
    # Extract per_task limit for this agent  
    $perTaskLimit = $null
    if ($budgetsContent -match "${Agent}:\s+(\d+).*?per_task") {
        # Try to find per-task override (next occurrence)
        $idx = $budgetsContent.IndexOf($Agent)
        if ($idx -gt 0) {
            $chunk = $budgetsContent.Substring($idx)
            if ($chunk -match "per_task.*?${Agent}:\s+(\d+)") {
                $perTaskLimit = [int]$matches[1]
            }
        }
    }
    if ($null -eq $perTaskLimit) {
        if ($budgetsContent -match "per_task:.*?default:\s+(\d+)") {
            $perTaskLimit = [int]$matches[1]
        }
    }
    
    # Extract enforcement mode
    $enforcementSession = "soft"
    $enforcementTask = "soft"
    if ($budgetsContent -match "per_session:\s+(hard|soft)") { $enforcementSession = $matches[1] }
    if ($budgetsContent -match "per_task:\s+(hard|soft)") { $enforcementTask = $matches[1] }
    
    # Read current session usage from token_budget.yaml
    $sessionTokens = 0
    $agentTokens = 0
    if ($content -match "session_tokens:\s+(\d+)") { $sessionTokens = [int]$matches[1] }
    if ($content -match [regex]::Escape("  ${Agent}:") + "\s+(\d+)") {
        $agentTokens = [int]$matches[1]
    }
    
    # Estimate task tokens (use provided $Tokens param or estimate)
    $taskTokens = if ($Tokens -gt 0) { $Tokens } else { 8000 }  # default estimate
    
    # Calculate projected totals
    $projectedSession = $sessionTokens + $taskTokens
    $projectedAgent = $agentTokens + $taskTokens
    
    # Determine budget limits (use defaults if not found in budgets.yaml)
    $defaultSessionLimit = 50000
    $defaultTaskLimit = 8000
    if ($null -eq $perSessionLimit) { $perSessionLimit = $defaultSessionLimit }
    if ($null -eq $perTaskLimit) { $perTaskLimit = $defaultTaskLimit }
    
    # Check per-session budget
    $sessionOver = $projectedSession -gt $perSessionLimit
    $agentOver = $projectedAgent -gt ($perSessionLimit * 0.8)  # 80% soft warning
    
    # Check per-task budget
    $taskOver = $taskTokens -gt $perTaskLimit
    
    # Determine output and exit code
    $exitCode = 0
    $signal = "GO"
    $reason = ""
    
    if ($sessionOver -and $enforcementSession -eq "hard") {
        $exitCode = 1
        $signal = "REJECT"
        $reason = "per_session hard limit would exceed ($projectedSession > $perSessionLimit)"
    } elseif ($sessionOver) {
        $exitCode = 2
        $signal = "WARN"
        $reason = "per_session soft limit would exceed ($projectedSession > $perSessionLimit)"
    } elseif ($agentOver) {
        $exitCode = 2
        $signal = "WARN"
        $reason = "agent 80% budget threshold ($projectedAgent > " + ($perSessionLimit * 0.8) + ")"
    }
    
    # Output format: SIGNAL|reason|sessionUsed/sessionLimit|agentUsed/agentLimit|taskEst/taskLimit
    $output = "${signal}|${reason}|${sessionTokens}/${perSessionLimit}|${agentTokens}/${perSessionLimit}|${taskTokens}/${perTaskLimit}"
    Write-Host $output
    exit $exitCode
}
