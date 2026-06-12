#!/usr/bin/env pwsh
# handover-validate.ps1
# Validates a handoff JSON file against memory/handover/schema.json
# Usage: pwsh handover-validate.ps1 -HandoffFile <path>
# Exit 0 = valid, Exit 1 = invalid

param(
    [Parameter(Mandatory=$true)]
    [string]$HandoffFile
)

$SCHEMA_PATH = Join-Path $PSScriptRoot "..\memory\handover\schema.json"
$handoffDir = Join-Path $PSScriptRoot "..\memory\handover"

# Resolve absolute path
$HandoffFile = (Resolve-Path $HandoffFile -ErrorAction SilentlyContinue).Path
if (-not $HandoffFile) {
    Write-Error "Handoff file not found: $HandoffFile"
    exit 1
}

# Read files
try {
    $schema = Get-Content $SCHEMA_PATH -Raw | ConvertFrom-Json
    $handoff = Get-Content $HandoffFile -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse JSON: $_"
    exit 1
}

$errors = @()

# Check required fields
foreach ($field in $schema.required_fields.PSObject.Properties) {
    $name = $field.Name
    if (-not ($handoff.PSObject.Properties.Name -contains $name)) {
        $errors += "Missing required field: $name"
    }
}

# Validate task_id format (YYYY-MM-DD-NNN)
if ($handoff.task_id -and $handoff.task_id -notmatch '^\d{4}-\d{2}-\d{2}-\d{3,}$') {
    $errors += "task_id format invalid (expected YYYY-MM-DD-NNN): $($handoff.task_id)"
}

# Validate priority if present
if ($handoff.priority) {
    $validPriorities = @('low', 'medium', 'high', 'critical')
    if ($validPriorities -notcontains $handoff.priority) {
        $errors += "priority invalid (must be low/medium/high/critical): $($handoff.priority)"
    }
}

# Validate verify_command is non-empty
if ($handoff.verify_command -and [string]::IsNullOrWhiteSpace($handoff.verify_command)) {
    $errors += "verify_command is empty"
}

# Check input has files array if input exists
if ($handoff.input -and -not $handoff.input.files) {
    $errors += "input.files missing or empty"
}

# Check expected_output has tier_evidence
if ($handoff.expected_output -and $handoff.expected_output.tier_evidence -eq $null) {
    $errors += "expected_output.tier_evidence missing"
}

# Report
if ($errors.Count -gt 0) {
    Write-Host "[HANDOFF INVALID] $HandoffFile" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
    exit 1
}

Write-Host "[HANDOFF VALID] $HandoffFile" -ForegroundColor Green
Write-Host "  task_id: $($handoff.task_id)"
Write-Host "  from: $($handoff.from_agent) -> to: $($handoff.to_agent)"
Write-Host "  intent: $($handoff.intent)"
exit 0
