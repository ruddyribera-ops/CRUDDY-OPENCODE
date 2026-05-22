# post-edit.ps1 — Auto test runner hook
# Fires after Write, Edit, or MultiEdit tool calls
# Input: JSON via stdin with tool_input.file_path

param()

try {
    $stdinRaw = [Console]::In.ReadToEnd()
    if (-not $stdinRaw -or $stdinRaw.Trim() -eq '') { exit 0 }

    $data = $stdinRaw | ConvertFrom-Json -ErrorAction Stop
    $filePath = $data.tool_input.file_path
    if (-not $filePath) { exit 0 }

    # Only process code files
    $codeExts = @('.py', '.ts', '.tsx', '.js', '.jsx', '.go', '.php')
    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
    if ($codeExts -notcontains $ext) { exit 0 }

    # Walk up directory tree to find project root
    $dir = [System.IO.Path]::GetDirectoryName($filePath)
    $rootMarkers = @('package.json', 'pyproject.toml', 'pytest.ini', 'go.mod', 'composer.json')
    $projectRoot = $null
    $current = $dir
    while ($current -and $current -ne [System.IO.Path]::GetPathRoot($current)) {
        foreach ($marker in $rootMarkers) {
            if (Test-Path (Join-Path $current $marker)) {
                $projectRoot = $current
                break
            }
        }
        if ($projectRoot) { break }
        $current = [System.IO.Path]::GetDirectoryName($current)
    }
    if (-not $projectRoot) { exit 0 }

    # Detect test runner
    $runner = $null
    $runnerArgs = @()
    $scope = $null

    if (Test-Path (Join-Path $projectRoot 'package.json')) {
        $pkg = Get-Content (Join-Path $projectRoot 'package.json') -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkg.scripts.test) {
            $runner = 'npm'
            $runnerArgs = @('test', '--', '--passWithNoTests')
        }
    }
    if (-not $runner -and (Test-Path (Join-Path $projectRoot 'pyproject.toml') -or Test-Path (Join-Path $projectRoot 'pytest.ini'))) {
        $runner = 'pytest'
        # Try to find matching test file
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $testCandidates = @(
            (Join-Path $projectRoot "tests\test_$baseName.py"),
            (Join-Path $projectRoot "test\test_$baseName.py"),
            (Join-Path $projectRoot "tests\${baseName}_test.py")
        )
        foreach ($tc in $testCandidates) {
            if (Test-Path $tc) { $scope = $tc; break }
        }
        if ($scope) { $runnerArgs = @($scope, '-v', '--tb=short') }
        else { $runnerArgs = @('-v', '--tb=short', '-q') }
    }
    if (-not $runner -and (Test-Path (Join-Path $projectRoot 'go.mod'))) {
        $runner = 'go'
        $runnerArgs = @('test', './...')
    }
    if (-not $runner) { exit 0 }

    Write-Host ""
    Write-Host "[HOOK: post-edit] $([System.IO.Path]::GetFileName($filePath)) — runner: $runner"
    if ($scope) { Write-Host "  scope: $([System.IO.Path]::GetFileName($scope))" }

    # Run tests with 60s timeout
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $runner
    $psi.Arguments = $runnerArgs -join ' '
    $psi.WorkingDirectory = $projectRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    $finished = $proc.WaitForExit(60000)
    if (-not $finished) {
        $proc.Kill()
        Write-Host "[HOOK: post-edit] TIMEOUT — test run killed after 60s"
        exit 0
    }

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $combined = ($stdout + $stderr).Trim()
    $exitCode = $proc.ExitCode

    # Print last 30 lines
    $lines = $combined -split "`n"
    $tail = if ($lines.Count -gt 30) { $lines[($lines.Count - 30)..($lines.Count - 1)] } else { $lines }

    if ($exitCode -ne 0) {
        Write-Host "[TEST FAILURE] exit=$exitCode"
    } else {
        Write-Host "[TESTS PASS] exit=0"
    }
    $tail | ForEach-Object { Write-Host "  $_" }

} catch {
    # Log to persistent location (visible to user)
    $logDir = "$env:USERPROFILE\.config\opencode"
    $logFile = "$logDir\hook-errors.log"
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] post-edit.ps1 error: $_" | Out-File -FilePath $logFile -Append -Encoding UTF8
        Write-Host "[HOOK: post-edit] Error logged to $logFile" -ForegroundColor DarkYellow
    } catch {}
}

exit 0
