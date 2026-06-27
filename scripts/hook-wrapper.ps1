#!/usr/bin/env pwsh
# ============================================================
# hook-wrapper.ps1 — Destructive command interceptor
# ============================================================
# Wraps bash/PowerShell commands to block destructive operations
# without explicit user confirmation. Workaround for OpenCode's
# lack of native tool-level hooks.
#
# Usage:
#   powershell scripts/hook-wrapper.ps1 "<command>"
#   echo "<command>" | powershell scripts/hook-wrapper.ps1
#
# Exit codes:
#   0 = allow (no match, or user confirmed)
#   1 = block (destructive pattern matched and user denied / timeout)
#
# Patterns intercepted (case-insensitive regex):
#   - rm -rf / rm -r -f / Remove-Item -Recurse -Force
#   - del /s /q
#   - git push --force / git push -f
#   - git reset --hard
#   - git clean -fd
#   - Format-Volume / Clear-Disk
#   - dd if=... of=/dev/...
#   - Invoke-Expression / iex ...
# ============================================================

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Command = ""
)

# ── Read command from args or stdin ──
if ([string]::IsNullOrWhiteSpace($Command)) {
  try {
    $Command = [Console]::In.ReadToEnd().Trim()
  } catch {
    # stdin not available — treat as empty (allow)
    exit 0
  }
}

if ([string]::IsNullOrWhiteSpace($Command)) {
  # No command = nothing to intercept
  exit 0
}

# ── Destructive patterns ──
$patterns = @(
  @{ name = "rm -rf / rm -r -f";            regex = "rm\s+-r[f]?\b" }
  @{ name = "Remove-Item -Recurse -Force";  regex = "Remove-Item\s+(-r|-recurse)\b.*(-fo|-force)\b" }
  @{ name = "del /s /q";                    regex = "del\s+/[sS]\s+/[qQ]\b" }
  @{ name = "git push --force";             regex = "git\s+push\s+(-f|--force)\b" }
  @{ name = "git reset --hard";             regex = "git\s+reset\s+--hard\b" }
  @{ name = "git clean -fd";                regex = "git\s+clean\s+-[fF][dD]\b" }
  @{ name = "Format-Volume";                regex = "Format-Volume\b" }
  @{ name = "Clear-Disk";                   regex = "Clear-Disk\b" }
  @{ name = "dd of=/dev/...";                regex = "dd\s+if=.*of=/dev/" }
  @{ name = "Invoke-Expression";            regex = "Invoke-Expression\b" }
  @{ name = "iex ...";                      regex = "\biex\s+" }
)

# ── Pattern matching ──
$matchedPattern = $null
foreach ($p in $patterns) {
  if ($Command -match $p.regex) {
    $matchedPattern = $p
    break
  }
}

if ($null -eq $matchedPattern) {
  # No match = allow
  exit 0
}

# ── Bash-Guardian checks (SP-3 AST-based) ──
$guardianDir = "$configDir\scripts\bash-guardian"
$guardianBlocked = $false
$guardianReason = ""

if (Test-Path $guardianDir) {
    # Run each guardian check
    $checks = @(
        @{ Name = "EnvVar"; Script = "EnvironmentVarCheck.ps1" }
        @{ Name = "Blacklist"; Script = "BlacklistCheck.ps1" }
        @{ Name = "VariableCommand"; Script = "VariableCommandCheck.ps1" }
        @{ Name = "PathAccess"; Script = "PathAccessCheck.ps1" }
    )

    foreach ($check in $checks) {
        $checkScript = Join-Path $guardianDir $check.Script
        if (Test-Path $checkScript) {
            try {
                $resultJson = & powershell -File $checkScript -Command $Command 2>$null
                if ($resultJson) {
                    $result = $resultJson | ConvertFrom-Json
                    if (-not $result.Allowed) {
                        $guardianBlocked = $true
                        $guardianReason = "Bash-Guardian [$($check.Name)]: $($result.Reason)"
                        break
                    }
                }
            } catch {
                # Non-blocking: guardian check failed, don't block on guardian error
            }
        }
    }
}

if ($guardianBlocked) {
    Write-Host ""
    Write-Host "BASH-GUARDIAN BLOCKED" -ForegroundColor Red -BackgroundColor Black
    Write-Host "  Reason: $guardianReason" -ForegroundColor Red
    Write-Host "  Command: $Command" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This command was blocked by bash-guardian security policy." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ── Match found — warn and prompt ──
Write-Host ""
Write-Host "DESTRUCTIVE COMMAND DETECTED" -ForegroundColor Red -BackgroundColor Black
Write-Host "  Pattern: $($matchedPattern.name)" -ForegroundColor Red
Write-Host "  Command: $Command" -ForegroundColor Yellow
Write-Host ""
Write-Host "This command is on the destructive list. Confirm to proceed." -ForegroundColor Yellow
Write-Host ""

# Read with timeout. In a non-interactive context (no TTY), this
# returns immediately with the default. In an interactive context,
# the user has 30 seconds to respond.
$response = "n"
try {
  # Use a host-aware prompt with timeout
  $host.UI.RawUI.FlushInputBuffer()
  $promptResult = $Host.UI.PromptForChoice(
    "Destructive command",
    "Allow this command? [Yes / No] (default No, 30s timeout)",
    @(
      [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Allow the command")
      [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Block the command")
    ),
    1  # default = No
  )
  # PromptForChoice returns 0 for Yes, 1 for No
  if ($promptResult -eq 0) {
    $response = "y"
  } else {
    $response = "n"
  }
} catch {
  # No interactive host available (non-TTY context) — block by default
  Write-Host "No interactive host — defaulting to N (block)" -ForegroundColor Yellow
  $response = "n"
}

if ($response -eq 'y') {
  Write-Host "Allowed." -ForegroundColor Green
  exit 0
} else {
  Write-Host "Blocked." -ForegroundColor Red
  exit 1
}
