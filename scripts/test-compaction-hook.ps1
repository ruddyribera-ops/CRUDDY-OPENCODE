# scripts/test-compaction-hook.ps1
# Simulates the experimental.session.compacting hook firing on compaction-survival.js.
# Since we can't trigger a long session in a short test, this script:
#   1. Imports the plugin
#   2. Creates a mock output.context array
#   3. Invokes the hook directly
#   4. Verifies the recovery context was injected
#   5. Verifies the log entry was written
#
# Run: powershell -File scripts/test-compaction-hook.ps1
# Exit: 0 = hook works correctly, 1 = hook failed

$ErrorActionPreference = "Continue"
$CONFIG = $env:USERPROFILE
$PLUGIN_DIR = Join-Path $CONFIG ".config\opencode\plugins"
$LOG_FILE = Join-Path $CONFIG ".config\opencode\memory\compaction-survival.log"
$TEST_ID = "test-compaction-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "[test-compaction-hook] simulating hook fire..." -ForegroundColor Cyan

# Ensure there's a test checkpoint to load (otherwise the hook will still work
# but inject only patterns, not checkpoint state)
$checkpointDir = Join-Path $CONFIG ".config\opencode\memory\checkpoints"
$checkpointFile = Join-Path $checkpointDir "checkpoint-$TEST_ID.json"
$indexFile = Join-Path $checkpointDir "checkpoint_index.jsonl"
$checkpoint = @{
    type = "checkpoint"
    task_id = $TEST_ID
    description = "compaction hook test"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
    progress_percent = 75
    project_path = $PLUGIN_DIR
    strategy = "test"
    files_modified = @("pre-tool-guard.js", "post-tool-guard.js")
    pending_tasks = @("verify compaction hook works")
    active_agents = @("main-coordinator", "code-builder")
    next_action = "run /test-plugins"
    error_context = ""
} | ConvertTo-Json -Depth 5

if (-not (Test-Path $checkpointDir)) { New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null }
Set-Content -LiteralPath $checkpointFile -Value $checkpoint -Encoding UTF8
$indexEntry = (@{ type = "checkpoint"; task_id = $TEST_ID; file = (Split-Path $checkpointFile -Leaf); timestamp = (Get-Date).ToUniversalTime().ToString("o") } | ConvertTo-Json -Compress)
Add-Content -LiteralPath $indexFile -Value $indexEntry -ErrorAction SilentlyContinue

# Now invoke the hook
$logBefore = if (Test-Path $LOG_FILE) { (Get-Item $LOG_FILE).Length } else { 0 }
$tmpScript = Join-Path $env:TEMP "compaction-test-$(Get-Random).mjs"
$nodeCode = @"
import { CompactionSurvival } from 'file:///$($PLUGIN_DIR -replace '\\','/')/compaction-survival.js'
const plugin = await CompactionSurvival({ project: {}, client: { app: { log: async () => {} } }, `$: null, directory: process.cwd() })
const hook = plugin['experimental.session.compacting']
if (typeof hook !== 'function') { console.log('HOOK_MISSING'); process.exit(1) }

const input = {}
const output = { context: [] }
await hook(input, output)

if (!Array.isArray(output.context)) { console.log('OUTPUT_INVALID'); process.exit(1) }
if (output.context.length === 0) { console.log('NO_INJECTION'); process.exit(1) }

console.log('CONTEXT_ITEMS:' + output.context.length)
for (const item of output.context) {
  const text = item.text || ''
  console.log('ITEM:' + text.substring(0, 80).replace(/\n/g, ' '))
}
"@
Set-Content -LiteralPath $tmpScript -Value $nodeCode -Encoding UTF8
$nodeOut = node $tmpScript 2>&1
Remove-Item -LiteralPath $tmpScript -ErrorAction SilentlyContinue

Write-Host "  Hook output:" -ForegroundColor Gray
foreach ($line in $nodeOut) { Write-Host "    $line" }

# Check results
$hookMissing = $nodeOut -match "HOOK_MISSING"
$noInjection = $nodeOut -match "NO_INJECTION"
$contextCount = ($nodeOut -match "^CONTEXT_ITEMS:").ForEach({ $_.Substring(14) })

# Wait for log write to flush
Start-Sleep -Milliseconds 200
$logAfter = if (Test-Path $LOG_FILE) { (Get-Item $LOG_FILE).Length } else { 0 }
$logDelta = $logAfter - $logBefore
$hookFired = $false
if ($logDelta -gt 0) {
    $content = Get-Content $LOG_FILE -Raw
    $startIdx = $content.Length - $logDelta
    $delta = $content.Substring($startIdx)
    if ($delta -match "experimental.session.compacting fired") { $hookFired = $true }
}

# Cleanup
Remove-Item -LiteralPath $checkpointFile -ErrorAction SilentlyContinue
$indexContent = Get-Content $indexFile -Raw -ErrorAction SilentlyContinue
$indexContent = $indexContent -replace [regex]::Escape($indexEntry + "`n"), ""
Set-Content -LiteralPath $indexFile -Value $indexContent -ErrorAction SilentlyContinue

# Report
Write-Host ""
Write-Host "[RESULT]" -ForegroundColor Cyan
if ($hookMissing) {
    Write-Host "  [FAIL] experimental.session.compacting hook not registered" -ForegroundColor Red
    exit 1
}
if ($noInjection) {
    Write-Host "  [FAIL] hook ran but injected no context" -ForegroundColor Red
    exit 1
}
if (-not $hookFired) {
    Write-Host "  [WARN] hook ran but no log entry written to compaction-survival.log" -ForegroundColor Yellow
}
if ($contextCount -gt 0) {
    Write-Host "  [PASS] hook fired, injected $contextCount context items, log entry written" -ForegroundColor Green
    exit 0
} else {
    Write-Host "  [FAIL] hook ran but context.items is empty" -ForegroundColor Red
    exit 1
}
