# Nightly Autoresearch Runner
# Scheduled task: "OpenCode Autoresearch Nightly"
# Runs daily at 02:00 via Task Scheduler

$ErrorActionPreference = "Continue"
$OPENCODE_ROOT = "<INSTALL_DIR>/.config\opencode"
$LOG_FILE = "$OPENCODE_ROOT\memory\autoresearch_nightly.log"
$VENV_PATH = "$OPENCODE_ROOT\factory\scripts\memory_retrieval\.venv"
$ITERATE_SCRIPT = "$OPENCODE_ROOT\factory\scripts\autoresearch\iterate.py"

# Ensure memory dir exists
$null = New-Item -ItemType Directory -Force -Path "$OPENCODE_ROOT\memory"

# Logging function
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp $Message" | Add-Content -Path $LOG_FILE -Encoding UTF8
}

Write-Log "=== Nightly Autoresearch Started ==="

# Activate venv if it exists, otherwise use system python
if (Test-Path "$VENV_PATH\Scripts\python.exe") {
    $PYTHON = "$VENV_PATH\Scripts\python.exe"
    Write-Log "Using venv Python: $PYTHON"
} else {
    $PYTHON = "python"
    Write-Log "Using system Python"
}

# Run iterate.py
$EXIT_CODE = 0
try {
    Write-Log "Running: python $ITERATE_SCRIPT --target $OPENCODE_ROOT\rules\challenger-rule.md --metric file_token_count --budget 4m --max-iter 8"
    & $PYTHON $ITERATE_SCRIPT --target "$OPENCODE_ROOT\rules\challenger-rule.md" --metric file_token_count --budget 4m --max-iter 8 2>&1 | ForEach-Object { Write-Log "  $_" }
    $EXIT_CODE = $LASTEXITCODE
    Write-Log "Exit code: $EXIT_CODE"
} catch {
    Write-Log "ERROR: $_"
    $EXIT_CODE = 1
}

Write-Log "=== Nightly Autoresearch Finished (exit $EXIT_CODE) ==="

# Exit 0 always — don't block other scheduled tasks
exit 0
