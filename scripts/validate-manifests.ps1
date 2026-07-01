# validate-manifests.ps1
# Validates all agent manifests using the canonical schema from agent-registry.py
#
# Canonical schema source: scripts/agent-registry.py (AGENT_SCHEMA)
# This script delegates to agent-registry.py validate and formats the output.
#
# Exit 0 = all valid, Exit 1 = errors found.

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$AgentsDir = Join-Path $ScriptDir "..\agents"

$errors = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()

Write-Host "=== Validating Agent Manifests ===" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Load schema from canonical source (agent-registry.py)
# ------------------------------------------------------------------
$schemaScript = Join-Path $ScriptDir "agent-registry.py"
if (-not (Test-Path -LiteralPath $schemaScript)) {
    Write-Host "ERROR: agent-registry.py not found at: $schemaScript" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# Call agent-registry.py validate and parse JSON output
# ------------------------------------------------------------------
try {
    $rawOutput = & python $schemaScript validate 2>&1
    $exitCode = $LASTEXITCODE
}
catch {
    Write-Host "ERROR: Failed to run agent-registry.py: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($exitCode -ne 0 -and $rawOutput -match "error|traceback") {
    Write-Host "ERROR: agent-registry.py exited with code $exitCode" -ForegroundColor Red
    Write-Host $rawOutput -ForegroundColor Red
    exit 1
}

try {
    $result = $rawOutput | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: Failed to parse agent-registry.py JSON output" -ForegroundColor Red
    Write-Host $rawOutput -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# Extract schema from agent-registry.py for reference
# ------------------------------------------------------------------
try {
    $schemaRaw = & python $schemaScript print-schema 2>&1
    $schemaResult = $schemaRaw | ConvertFrom-Json
    $requiredKeys = $schemaResult.schema.required_keys
    $optionalKeys = $schemaResult.schema.optional_keys
    Write-Host "Canonical schema (from agent-registry.py):" -ForegroundColor Gray
    Write-Host "  Required: $($requiredKeys -join ', ')" -ForegroundColor Gray
    Write-Host "  Optional: $($optionalKeys -join ', ')" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "WARNING: Could not load schema from agent-registry.py" -ForegroundColor Yellow
}

# ------------------------------------------------------------------
# Report validation results from agent-registry.py
# ------------------------------------------------------------------
$data = $result.data
$agentCount = $data.validated
$issueCount = $data.issues
$errorList = $data.errors
$warningList = $data.warnings
$infoList = $data.infos
$loadErrors = $data.load_errors

Write-Host "Validated $agentCount manifest(s)." -ForegroundColor Cyan
Write-Host ""

# Load errors (YAML parse failures)
if ($loadErrors -and $loadErrors.Count -gt 0) {
    foreach ($le in $loadErrors) {
        [void]$errors.Add("$($le.file): YAML parse error - $($le.error)")
    }
}

# Validation errors (missing required fields, etc.)
if ($errorList -and $errorList.Count -gt 0) {
    foreach ($e in $errorList) {
        $agent = if ($e.agent) { "$($e.agent): " } else { "" }
        [void]$errors.Add("${agent}$($e.field) - $($e.issue)")
    }
}

# Warnings
if ($warningList -and $warningList.Count -gt 0) {
    foreach ($w in $warningList) {
        [void]$warnings.Add($w.issue)
    }
}

# Infos
if ($infoList -and $infoList.Count -gt 0) {
    foreach ($i in $infoList) {
        [void]$warnings.Add($i.issue)
    }
}

# ------------------------------------------------------------------
# Report
# ------------------------------------------------------------------
if ($warnings.Count -gt 0) {
    Write-Host "=== $($warnings.Count) Warning(s) ===" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "  warn: $w" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($errors.Count -eq 0) {
    Write-Host "=== Result ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PASS: All $agentCount manifest(s) valid" -ForegroundColor Green
    if ($warnings.Count -gt 0) {
        Write-Host "   ($($warnings.Count) warning(s) - review above)" -ForegroundColor Yellow
    }
    exit 0
}
else {
    Write-Host "=== $($errors.Count) Error(s) Found ===" -ForegroundColor Red
    Write-Host ""
    foreach ($e in $errors) {
        Write-Host "  FAIL: $e" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "FAIL: Validation failed - $($errors.Count) error(s), $($warnings.Count) warning(s)" -ForegroundColor Red
    exit 1
}
