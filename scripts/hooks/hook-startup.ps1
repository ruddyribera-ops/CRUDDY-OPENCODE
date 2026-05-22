# hook-startup.ps1 — Session-start handler
# Surfaces any hook errors from previous session to user's attention

$configDir = "$env:USERPROFILE\.config\opencode"
$logFile = "$configDir\hook-errors.log"

if (Test-Path $logFile) {
    $errors = Get-Content $logFile -Raw
    $errorLines = $errors -split "`n" | Where-Object { $_ -match '\S' }

    if ($errorLines.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  OpenCode Hook Errors from Previous Session:" -ForegroundColor Yellow
        Write-Host "   (Review and delete $logFile when fixed)" -ForegroundColor DarkYellow
        Write-Host ""

        # Show last 10 errors
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
