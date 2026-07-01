# Memory Watcher Runner
# Scheduled task: "OpenCode Memory Watcher"
# Runs at user logon via Task Scheduler
# Stop by creating: C:\Users\Windows\.config\opencode\.opencode\watcher.stop

$ErrorActionPreference = "Continue"
$OPENCODE_ROOT = "C:\Users\Windows\.config\opencode"
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
