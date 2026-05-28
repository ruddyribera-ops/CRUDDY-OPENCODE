# hook-startup.ps1 — Session-start handler
# Surfaces any hook errors from previous session to user's attention
# Also initializes session state via T1 trigger

$configDir = "$env:USERPROFILE\.config\opencode"
$logFile = "$configDir\hook-errors.log"
$memoryDir = "$configDir\memory"
$scriptsDir = "$configDir\scripts"

# --- T1: Initialize session state ---
$sessionMachine = "$scriptsDir\session_machine.ps1"
if (Test-Path $sessionMachine) {
    try {
        & $sessionMachine -Trigger T1
    } catch {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] hook-startup.ps1: T1 failed: $_" |
                Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
    }
}

# --- Surface previous hook errors ---
if (Test-Path $logFile) {
    $errors = Get-Content $logFile -Raw
    $errorLines = $errors -split "`n" | Where-Object { $_ -match '\S' }

    if ($errorLines.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  OpenCode Hook Errors from Previous Session:" -ForegroundColor Yellow
        Write-Host "   (Review and delete $logFile when fixed)" -ForegroundColor DarkYellow
        Write-Host ""

        $tail = if ($errorLines.Count -gt 10) {
            $errorLines[($errorLines.Count - 10)..($errorLines.Count - 1)]
        } else {
            $errorLines
        }

        $tail | ForEach-Object {
            Write-Host "   $_" -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
}

        $tail | ForEach-Object {
            Write-Host "   $_" -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
}
