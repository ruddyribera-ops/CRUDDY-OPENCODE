# post-session-hook.ps1
# Analyzes the latest session log for errors and updates the feedback loop

$logDir = "$env:USERPROFILE\.local\share\opencode\log"
$memoryDir = "$env:USERPROFILE\.config\opencode\memory"
$feedbackFile = Join-Path $memoryDir "feedback_errors.md"

if (!(Test-Path $logDir)) {
    Write-Host "Log directory not found."
    exit 0
}

$latestLog = Get-ChildItem $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($null -eq $latestLog) {
    Write-Host "No logs found."
    exit 0
}

Write-Host "Analyzing $($latestLog.Name)..."

$errors = Get-Content $latestLog.FullName | Select-String -Pattern "ERROR|Exception|Access denied|Failed to" | Select-Object -First 10 -Unique

if ($errors) {
    if (!(Test-Path $feedbackFile)) {
        "# Session Error Feedback`n`n" | Set-Content $feedbackFile
    }
    
    $entry = "`n## [$([DateTime]::Now.ToString("yyyy-MM-dd HH:mm"))] Auto-detected from $($latestLog.Name)`n"
    foreach ($err in $errors) {
        $entry += "- $($err.ToString().Trim())`n"
    }
    
    Add-Content $feedbackFile -Value $entry
    Write-Host "Logged $($errors.Count) new error patterns to feedback_errors.md"
} else {
    Write-Host "No critical errors detected in the latest log."
}
