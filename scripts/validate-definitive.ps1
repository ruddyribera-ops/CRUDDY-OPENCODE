$ErrorActionPreference = "Stop"
$root = "C:\Users\Windows\.config\opencode"
$errors = New-Object System.Collections.Generic.List[string]

function Assert($cond, $msg) {
  if (-not $cond) { $script:errors.Add($msg) }
}

$configPath = Join-Path $root "opencode.json"
Assert (Test-Path -LiteralPath $configPath) "canonical opencode.json missing"
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
Assert ($cfg.default_agent -eq "main-coordinator") "default_agent not main-coordinator"
Assert ($cfg.lsp -eq $true) "native lsp not enabled"
Assert (Test-Path -LiteralPath (Join-Path $root "plugins\session-title-guard.js")) "session-title-guard plugin missing"
Assert (Test-Path -LiteralPath (Join-Path $root "plugins\memory-bridge.js")) "memory-bridge plugin missing"
Assert (Test-Path -LiteralPath (Join-Path $root "skills\cs-fundamentals\SKILL.md")) "cs-fundamentals skill missing"
Assert (-not (Test-Path -LiteralPath "C:\Users\Windows\opencode.json")) "duplicate home opencode.json still exists"
Assert (-not (Test-Path -LiteralPath "C:\Users\Windows\.opencode")) "duplicate home .opencode still exists"
Assert (-not (Test-Path -LiteralPath "C:\Users\Windows\AppData\Roaming\opencode\opencode.json")) "duplicate AppData opencode.json still exists"
Assert (-not (Test-Path -LiteralPath (Join-Path $root "opencode.json.bak"))) "duplicate opencode.json.bak still exists"

foreach ($mcpName in @($cfg.mcp.PSObject.Properties.Name)) {
  $mcp = $cfg.mcp.$mcpName
  Assert (-not ($mcp.PSObject.Properties.Match("env").Count -gt 0)) "mcp $mcpName still uses env instead of environment"
}

$agentFiles = Get-ChildItem -LiteralPath (Join-Path $root "agents") -Filter "*.md" |
  Where-Object { $_.Name -ne "SPECIALIZED_AGENTS.md" }
foreach ($agent in $agentFiles) {
  $text = Get-Content -LiteralPath $agent.FullName -Raw
  Assert ($text -match "(?m)^mode:\s*(primary|subagent)") "agent $($agent.Name) missing native mode"
  Assert ($text -match "(?m)^permission:") "agent $($agent.Name) missing permissions"
}

$profile = "C:\Users\Windows\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if (Test-Path -LiteralPath $profile) {
  $raw = Get-Content -LiteralPath $profile -Raw
  Assert (-not ($raw -match 'OPENCODE_API_KEY\s*=\s*"sk-')) "plaintext OPENCODE_API_KEY still in profile"
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Host "FAIL: $_" }
  exit 1
}
Write-Host "PASS: definitive OpenCode config validated."