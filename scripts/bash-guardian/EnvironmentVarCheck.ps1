# EnvironmentVarCheck.ps1
# SP-3: Blocks forbidden env vars (LD_PRELOAD, PATH injection, etc.)

param(
    [string]$Command = "",
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "SilentlyContinue"
$configDir = "$env:USERPROFILE\.config\opencode"

# Load config
$forbiddenVars = @('LD_PRELOAD', 'LD_LIBRARY_PATH', 'SHELL', 'IFS', 'HOME', 'PATH')
$wrapperCommands = @('sudo', 'timeout', 'time', 'nice', 'nohup', 'strace', 'ltrace', 'env', 'watch', 'xargs', 'parallel', 'caffeinate', 'unbuffer', 'exec', 'eval', 'sh', 'bash', 'zsh')

if ($ConfigPath -and (Test-Path $ConfigPath)) {
    try {
        $yamlContent = Get-Content $ConfigPath -Raw
        # Simple YAML parsing for forbidden_env_vars
        if ($yamlContent -match 'forbidden_env_vars:\s*\n((?:\s+-\s+\w+\s*\n)+)') {
            $matchesBlock = $matches[1]
            $forbiddenVars = [regex]::Matches($matchesBlock, '(?<=-\s+)\w+') | ForEach-Object { $_.Value }
        }
    } catch {}
}

function Test-ForbiddenEnvVar {
    param([string]$Cmd)

    # Pattern 1: VAR=value before command (env VAR=value command)
    # Match: export VAR=value, env VAR=value, VAR=value command
    if ($Cmd -match '^\s*(export\s+)?([A-Z_][A-Z0-9_]*)=(.*?)(\s+(?:\S+.*))?$') {
        $varName = $matches[2]
        if ($forbiddenVars -contains $varName) {
            return "Forbidden environment variable: $varName"
        }
    }

    # Pattern 2: Inline env setting before command (env VAR=value cmd args)
    $envPattern = '(?i)\b(env|export)\s+([A-Z_][A-Z0-9_]*)=([^\s]+)'
    if ($Cmd -match $envPattern) {
        $varName = $matches[2]
        if ($forbiddenVars -contains $varName) {
            return "Forbidden environment variable in export/env: $varName"
        }
    }

    # Pattern 3: Assignment before command
    $assignmentPattern = '(?i)([A-Z_][A-Z0-9_]*)='
    $parts = $Cmd -split '\s+'
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $part = $parts[$i]
        if ($part -match '^([A-Z_][A-Z0-9_]*)=(.*)$') {
            $varName = $matches[1]
            if ($forbiddenVars -contains $varName) {
                # Check if this is before an actual command (not just the whole line being assignment)
                $rest = $parts[($i + 1)..($parts.Count - 1)] -join ' '
                if ($rest -match '^\s*\S') {
                    return "Forbidden environment variable assignment: $varName"
                }
            }
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($Command)) {
    return @{ Allowed = $true; Reason = "Empty command" } | ConvertTo-Json -Compress
}

$result = Test-ForbiddenEnvVar -Cmd $Command

if ($result) {
    @{ Allowed = $false; Reason = $result } | ConvertTo-Json -Compress
} else {
    @{ Allowed = $true; Reason = "No forbidden env vars detected" } | ConvertTo-Json -Compress
}