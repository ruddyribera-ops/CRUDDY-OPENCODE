# validate-manifests.ps1
# Validates all agent manifests against agent-schema.yaml
#
# Reads every agents/*.yaml file (excluding agent-schema.yaml itself),
# validates structure, keys, and cross-references against the schema.
#
# Exit 0 = all valid, Exit 1 = errors found.

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$AgentsDir = Join-Path $ScriptDir "..\agents"
$SchemaFile = Join-Path $AgentsDir "agent-schema.yaml"

$ValidRoles = @("coordinator", "executor", "analyzer", "decider", "reporter", "generator", "curator")

$ValidMcpPatterns = @(
    "bash", "read", "write", "edit", "glob", "grep",
    "context7_query-docs", "context7_resolve-library-id",
    "sequential-thinking_sequentialthinking",
    "fetch_fetch", "webfetch", "task",
    "memory_*", "desktop-commander_*", "filesystem_*"
)

$TierModelMap = @{
    1 = "opencode-go/deepseek-v4-flash"
    2 = "opencode-go/deepseek-v4-pro"
    3 = "opencode-go/minimax-m2.7"
}

$errors = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()

Write-Host "=== Validating Agent Manifests ===" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Helper: collect all .yaml files in agents/ (excluding schema)
# ------------------------------------------------------------------
$manifestFiles = @(Get-ChildItem -LiteralPath $AgentsDir -Filter "*.yaml" -File |
    Where-Object { $_.Name -ne "agent-schema.yaml" })

if ($manifestFiles.Count -eq 0) {
    Write-Host "No agent manifests found in: $AgentsDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($manifestFiles.Count) manifest(s) to validate." -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Helper: collect valid agent names (for dependency checking)
# ------------------------------------------------------------------
$validAgentNames = @($manifestFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })

# ------------------------------------------------------------------
# Helper: check if a tool name matches any of the valid MCP patterns
# ------------------------------------------------------------------
function Test-ValidMcpTool {
    param([string]$ToolName)
    foreach ($pattern in $ValidMcpPatterns) {
        if ($pattern.EndsWith("*")) {
            $prefix = $pattern.TrimEnd("*")
            if ($ToolName.StartsWith($prefix)) { return $true }
        } elseif ($ToolName -eq $pattern) {
            return $true
        }
    }
    return $false
}

# ------------------------------------------------------------------
# Helper: parse YAML with basic string-list awareness
# PowerShell 5.1 does not have native YAML parsing. We use a regex-based
# approach that handles the simple key:value and list structures used
# in our agent manifests.
# ------------------------------------------------------------------
function Read-AgentManifest {
    param([string]$FilePath)
    $lines = Get-Content -LiteralPath $FilePath -Encoding UTF8

    $data = @{
        _order = [System.Collections.ArrayList]::new()
    }
    $currentKey = $null
    $currentList = [System.Collections.ArrayList]::new()
    $inList = $false
    $lineNumber = 0
    $listStartLine = 0

    foreach ($line in $lines) {
        $lineNumber++
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }

        if ($line -match '^(\w[\w_-]*)\s*:\s*$') {
            # Key with list start on next lines
            if ($inList) {
                $data[$currentKey] = $currentList.ToArray()
                $data["${currentKey}_line"] = $listStartLine
            }
            $currentKey = $Matches[1]
            $currentList = [System.Collections.ArrayList]::new()
            $inList = $true
            $listStartLine = $lineNumber
            [void]$data._order.Add($currentKey)
        }
        elseif ($inList -and $line -match '^\s+-\s+(.+)$') {
            [void]$currentList.Add($Matches[1].Trim())
        }
        elseif ($inList -and $line -match '^\s+\[\s*\]\s*$') {
            # Empty list
        }
        elseif ($line -match '^(\w[\w_-]*)\s*:\s*(.+)$') {
            if ($inList) {
                $data[$currentKey] = $currentList.ToArray()
                $data["${currentKey}_line"] = $listStartLine
                $inList = $false
            }
            $currentKey = $Matches[1]
            $value = $Matches[2].Trim()
            # Strip quotes if present
            if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
                $value = $Matches[1]
            }
            $data[$currentKey] = $value
            $data["${currentKey}_line"] = $lineNumber
            [void]$data._order.Add($currentKey)
            $inList = $false
        }
    }
    if ($inList) {
        $data[$currentKey] = $currentList.ToArray()
        $data["${currentKey}_line"] = $listStartLine
    }
    return $data
}

# ------------------------------------------------------------------
# Validate each manifest
# ------------------------------------------------------------------
foreach ($file in $manifestFiles) {
    $fileName = $file.Name
    $agentName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $filePath = $file.FullName

    Write-Host "  Checking: $fileName" -ForegroundColor White

    try {
        $m = Read-AgentManifest -FilePath $filePath
    }
    catch {
        $errMsg = "Failed to read file: $($_.Exception.Message)"
        [void]$errors.Add("$fileName`t$errMsg")
        continue
    }

    # --- 1. Required keys ---
    $requiredKeys = @("name", "version", "description", "model_tier", "capabilities", "skills_used", "role", "guardrails")
    foreach ($key in $requiredKeys) {
        if (-not $m.ContainsKey($key)) {
            [void]$errors.Add("$fileName`tMissing required key: '$key'")
        }
    }

    # --- 2. Name must match filename ---
    if ($m.ContainsKey("name") -and $m["name"] -ne $agentName) {
        [void]$errors.Add("$fileName`tname '$($m["name"])' does not match filename '$agentName'")
    }

    # --- 3. Role must be valid enum ---
    if ($m.ContainsKey("role")) {
        $role = $m["role"]
        if ($role -notin $ValidRoles) {
            $validList = $ValidRoles -join ", "
            [void]$errors.Add("$fileName`tInvalid role '$role'. Must be one of: $validList")
        }
    }

    # --- 4. Model tier 1-3 + model consistency ---
    if ($m.ContainsKey("model_tier")) {
        $tier = $m["model_tier"]
        try {
            $tierNum = [int]$tier
            if ($tierNum -lt 1 -or $tierNum -gt 3) {
                [void]$errors.Add("$fileName`tmodel_tier '$tier' is out of range (1-3)")
            }
            if ($m.ContainsKey("model")) {
                $expectedModel = $TierModelMap[$tierNum]
                if ($m["model"] -ne $expectedModel) {
                    [void]$errors.Add("$fileName`tmodel '$($m["model"])' does not match tier $tierNum (expected '$expectedModel')")
                }
            }
        }
        catch {
            [void]$errors.Add("$fileName`tmodel_tier '$tier' is not a valid integer")
        }
    }

    # --- 5. Capabilities >= 3 ---
    if ($m.ContainsKey("capabilities")) {
        $caps = $m["capabilities"]
        if ($caps -is [array]) {
            if ($caps.Count -lt 3) {
                [void]$errors.Add("$fileName`tcapabilities has $($caps.Count) items, minimum 3 required")
            }
        }
        else {
            [void]$errors.Add("$fileName`tcapabilities is not a list")
        }
    }

    # --- 6. Guardrails >= 3 ---
    if ($m.ContainsKey("guardrails")) {
        $gr = $m["guardrails"]
        if ($gr -is [array]) {
            if ($gr.Count -lt 3) {
                [void]$errors.Add("$fileName`tguardrails has $($gr.Count) items, minimum 3 required")
            }
        }
        else {
            [void]$errors.Add("$fileName`tguardrails is not a list")
        }
    }

    # --- 7. Dependencies: no self-reference, each references existing agent ---
    if ($m.ContainsKey("dependencies")) {
        $deps = $m["dependencies"]
        if ($deps -is [array]) {
            if ($deps.Count -gt 5) {
                [void]$errors.Add("$fileName`tdependencies has $($deps.Count) items, maximum 5 allowed")
            }
            foreach ($dep in $deps) {
                if ($dep -eq $agentName) {
                    [void]$errors.Add("$fileName`tSelf-dependency detected: '$agentName' depends on itself")
                }
                elseif ($dep -notin $validAgentNames) {
                    [void]$errors.Add("$fileName`tDependency '$dep' does not match any existing agent in agents/")
                }
            }
        }
    }

    # --- 8. MCP tools validation ---
    if ($m.ContainsKey("mcp_tools_allowed")) {
        $allowed = $m["mcp_tools_allowed"]
        if ($allowed -is [array]) {
            foreach ($tool in $allowed) {
                if (-not (Test-ValidMcpTool -ToolName $tool)) {
                    [void]$warnings.Add("$fileName`tUnrecognized MCP tool in mcp_tools_allowed: '$tool'")
                }
            }
        }
    }

    # --- 9. version format check ---
    if ($m.ContainsKey("version")) {
        $ver = $m["version"]
        if ($ver -notmatch '^\d+\.\d+\.\d+$') {
            [void]$warnings.Add("$fileName`tversion '$ver' does not follow SemVer (X.Y.Z)")
        }
    }

    # --- 10. model present check (optional key, but warn if missing) ---
    if (-not $m.ContainsKey("model")) {
        [void]$warnings.Add("$fileName`t'model' key not specified (will default based on model_tier)")
    }
}

# ------------------------------------------------------------------
# Report
# ------------------------------------------------------------------

# Print warnings first
if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "=== $($warnings.Count) Warning(s) ===" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "  warn: $w" -ForegroundColor Yellow
    }
}

# Print errors
if ($errors.Count -eq 0) {
    Write-Host ""
    Write-Host "=== Result ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PASS: All $($manifestFiles.Count) manifest(s) valid" -ForegroundColor Green
    if ($warnings.Count -gt 0) {
        Write-Host "   ($($warnings.Count) warning(s) - review above)" -ForegroundColor Yellow
    }
    exit 0
}
else {
    Write-Host ""
    Write-Host "=== $($errors.Count) Error(s) Found ===" -ForegroundColor Red
    Write-Host ""
    foreach ($e in $errors) {
        Write-Host "  FAIL: $e" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "FAIL: Validation failed - $($errors.Count) error(s), $($warnings.Count) warning(s)" -ForegroundColor Red
    exit 1
}
