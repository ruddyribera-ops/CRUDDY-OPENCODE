$ErrorActionPreference = "Stop"
$root = "$env:USERPROFILE\.config\opencode"
$errors = New-Object System.Collections.Generic.List[string]

function Assert($cond, $msg) {
  if (-not $cond) { $script:errors.Add($msg) }
}

$configPath = Join-Path $root "opencode.json"
Assert (Test-Path -LiteralPath $configPath) "canonical opencode.json missing"
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
Assert ($cfg.default_agent -eq "main-coordinator") "default_agent not main-coordinator"

# Check for duplicate config files (leftover from mis-installed packages)
Assert (-not (Test-Path -LiteralPath "C:\Users\Windows\.opencode")) "duplicate home .opencode still exists"
Assert (-not (Test-Path -LiteralPath "C:\Users\Windows\opencode.json")) "duplicate home opencode.json still exists"
Assert (-not (Test-Path -LiteralPath "$env:APPDATA\opencode\opencode.json")) "duplicate AppData opencode.json still exists"
Assert (-not (Test-Path -LiteralPath (Join-Path $root "opencode.json.bak"))) "duplicate opencode.json.bak still exists"

# Check no MCP uses old 'env' key instead of 'environment'
foreach ($mcpName in @($cfg.mcp.PSObject.Properties.Name)) {
  $mcp = $cfg.mcp.$mcpName
  if ($mcp.PSObject.Properties.Match("env").Count -gt 0) {
    $script:errors.Add("mcp $mcpName uses deprecated 'env' key - use 'environment' instead")
  }
}

# Check agent files have native manifest fields
$agentFiles = Get-ChildItem -LiteralPath (Join-Path $root "agents") -Filter "*.md" |
  Where-Object { $_.Name -ne "SPECIALIZED_AGENTS.md" }
foreach ($agent in $agentFiles) {
  $text = Get-Content -LiteralPath $agent.FullName -Raw
  if ($text -notmatch "(?m)^mode:\s*(primary|subagent)") {
    $script:errors.Add("agent $($agent.Name) missing 'mode:' field - required for native manifest")
  }
  if ($text -notmatch "(?m)^permission:") {
    $script:errors.Add("agent $($agent.Name) missing 'permission:' section - required for native manifest")
  }
}

# Check PowerShell profile for plaintext API keys (security)
$profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path -LiteralPath $profile) {
  $raw = Get-Content -LiteralPath $profile -Raw
  if ($raw -match 'OPENAI_API_KEY\s*=\s*"sk-') {
    $script:errors.Add("plaintext OPENAI_API_KEY found in PowerShell profile - security risk")
  }
  if ($raw -match 'OPENCODE_API_KEY\s*=\s*"sk-') {
    $script:errors.Add("plaintext OPENCODE_API_KEY found in PowerShell profile - security risk")
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Host "FAIL: $_" }
  exit 1
}
Write-Host "PASS: definitive OpenCode config validated."