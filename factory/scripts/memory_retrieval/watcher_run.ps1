# Memory Watcher Runner
# Scheduled task: "OpenCode Memory Watcher"
# Runs at user logon via Task Scheduler
# Stop by creating: C:\Users\Windows\.config\opencode\.opencode\watcher.stop

$ErrorActionPreference = "Continue"
$OPENCODE_ROOT = if ($env:OPENCODE_CONFIG_HOME) { $env:OPENCODE_CONFIG_HOME }
                elseif ($env:USERPROFILE) { Join-Path $env:USERPROFILE ".config\opencode" }
                elseif ($env:HOME) { Join-Path $env:HOME ".config/opencode" }
                else { "$PSScriptRoot\..\.." }
$VENV_PATH = "$OPENCODE_ROOT\scripts\memory_retrieval\.venv"
$WATCHER_SCRIPT = "$OPENCODE_ROOT\factory\scripts\memory_retrieval\watcher.py"

# Activate venv if it exists, otherwise use system python
if (Test-Path "$VENV_PATH\Scripts\python.exe") {
    $PYTHON = "$VENV_PATH\Scripts\python.exe"
} else {
    $PYTHON = "python"
}

# Run watcher — stays in foreground, managed by Task Scheduler
& $PYTHON $WATCHER_SCRIPT
exit $LASTEXITCODE
