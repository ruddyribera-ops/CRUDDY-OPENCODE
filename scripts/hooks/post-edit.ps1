# post-edit.ps1 — Auto test runner hook
# Fires after file modifications
# Usage: post-edit.ps1 -FilePath "path/to/file.py"
# Exit codes: 0 = ran/no tests, 1 = failure, 2 = not a code file

param(
    [string]$FilePath = $null
)

if (-not $FilePath) {
    # Try reading from stdin as JSON (for backward compat)
    $stdinRaw = ""
    if ($input) {
        $stdinRaw = $input | Out-String
    } else {
        try { $stdinRaw = [Console]::In.ReadToEnd() } catch {}
    }
    if ($stdinRaw -and $stdinRaw.Trim() -ne '') {
        try {
            $data = $stdinRaw | ConvertFrom-Json -ErrorAction Stop
            $FilePath = $data.tool_input.file_path
        } catch {
            # Not valid JSON, skip
            exit 0
        }
    }
}

if (-not $FilePath) { exit 0 }

# Only process code files
$codeExts = @('.py', '.ts', '.tsx', '.js', '.jsx', '.go', '.php')
$ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
if ($codeExts -notcontains $ext) { exit 0 }

# ── Special case: OpenCode config file edit → run plugin test suite ──
# Any edit in ~/.config/opencode/plugins/ means a plugin changed.
# Run the regression test net to catch silent breakage immediately.
$configDir = Join-Path $env:USERPROFILE ".config\opencode"
$pluginsDir = Join-Path $configDir "plugins"
if ($FilePath -like (Join-Path $pluginsDir "*")) {
    $testScript = Join-Path $configDir "scripts\test-plugins.mjs"
    if (Test-Path $testScript) {
        Write-Host ""
        Write-Host "[HOOK: post-edit] OpenCode plugin file changed: $([System.IO.Path]::GetFileName($FilePath))"
        Write-Host "  → running plugin regression test..."
        $proc = Start-Process -FilePath "node" -ArgumentList "--test", "`"$testScript`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\plugin-test-out.log" -RedirectStandardError "$env:TEMP\plugin-test-err.log"
        if ($proc.ExitCode -ne 0) {
            Write-Host "[PLUGIN TEST FAILURE] exit=$($proc.ExitCode)"
            Get-Content "$env:TEMP\plugin-test-out.log" | Select-Object -Last 30 | ForEach-Object { Write-Host "  $_" }
            exit 1
        } else {
            Write-Host "[PLUGIN TESTS PASS] exit=0"
        }
        exit 0
    }
}

# Walk up directory tree to find project root
$dir = [System.IO.Path]::GetDirectoryName($FilePath)
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
    $pkg = Get-Content (Join-Path $projectRoot 'package.json') -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($pkg.scripts.test) {
        $runner = 'npm'
        $runnerArgs = @('test', '--', '--passWithNoTests')
    }
}
if (-not $runner -and ((Test-Path (Join-Path $projectRoot 'pyproject.toml')) -or (Test-Path (Join-Path $projectRoot 'pytest.ini')))) {
    $runner = 'pytest'
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
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
Write-Host "[HOOK: post-edit] $([System.IO.Path]::GetFileName($FilePath)) -- runner: $runner"
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
    Write-Host "[HOOK: post-edit] TIMEOUT -- test run killed after 60s"
    exit 0
}

$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()
$combined = ($stdout + $stderr).Trim()
$exitCode = $proc.ExitCode

# Print last 30 lines
$lines = $combined -split "`n"
$tailLines = @()
if ($lines.Count -gt 30) {
    for ($i = $lines.Count - 30; $i -lt $lines.Count; $i++) { $tailLines += $lines[$i] }
} else {
    $tailLines = $lines
}

if ($exitCode -ne 0) {
    Write-Host "[TEST FAILURE] exit=$exitCode"
} else {
    Write-Host "[TESTS PASS] exit=0"
}
foreach ($l in $tailLines) { Write-Host "  $l" }

exit $exitCode
