# VariableCommandCheck.ps1
# SP-3: Blocks $cmd, $(cmd), `cmd` as commands (not arguments)
# Allows them as arguments to legitimate commands

param(
    [string]$Command = "",
    [switch]$AllowVariableCommands
)

$ErrorActionPreference = "SilentlyContinue"

# Variable command patterns that are ALLOWED as arguments (not command position)
# Key insight: $foo in "echo $foo" is fine; $foo in "$foo arg" as first word is not
# Pattern = command that wraps/evaluates variables
$wrapperCommands = @('sudo', 'timeout', 'time', 'nice', 'nohup', 'strace', 'ltrace', 'env', 'watch', 'xargs', 'parallel', 'caffeinate', 'unbuffer', 'exec', 'eval', 'sh', 'bash', 'zsh')

function Test-VariableCommand {
    param([string]$Cmd, [bool]$AllowVars)

    if ($AllowVars) { return $null }

    $normalized = $Cmd.Trim()
    if (-not $normalized) { return $null }

    # Detect variable in command position (first word is a variable)
    # Pattern 1: $VAR at start
    if ($normalized -match '^\$([A-Z_][A-Z0-9_]*)\b') {
        return "Variable as command: `$$($matches[1])"
    }
    if ($normalized -match '^\$\{([A-Z_][A-Z0-9_]*)\}') {
        return "Variable as command: `${$($matches[1])}"
    }
    # Pattern 2: $(cmd) at start
    if ($normalized -match '^\$\(#[^\)]*\)') {
        return "Comment-substitution in command position"
    }
    if ($normalized -match '^\$\(([^)]+)\)') {
        $inside = $matches[1].Trim()
        # Ignore comments
        if (-not $inside.StartsWith('#')) {
            return "Command substitution as command: $($inside.Substring(0, [Math]::Min(20, $inside.Length)))..."
        }
    }
    # Pattern 3: `cmd` at start
    if ($normalized -match '^`([^`]+)`') {
        return "Backtick command substitution as command"
    }
    # Pattern 4: eval with variable
    if ($normalized -match '(?i)^\s*eval\b') {
        if ($normalized -match '\$\([^)]+\)' -or $normalized -match '\$[{A-Z]') {
            return "Variable expansion in eval"
        }
    }
    # Pattern 5: source with variable
    if ($normalized -match '(?i)^\s*(source|\.)\s+\$\{?\w') {
        return "Variable in source command"
    }
    # Pattern 6: Wrapper commands with variable expansion
    # e.g., sudo $cmd, timeout 5 $cmd
    $parts = $normalized -split '\s+'
    if ($parts.Count -gt 0) {
        $firstCmd = $parts[0]
        $firstBasename = if ($firstCmd -match '[\\/]') { $firstCmd -replace '.*[\\/]', '' } else { $firstCmd }
        if ($wrapperCommands -contains $firstBasename) {
            # Check remaining args for variable in command position
            $remaining = ($parts[1..($parts.Count - 1)] -join ' ').Trim()
            if ($remaining -match '^\$\(' -or $remaining -match '^`') {
                return "Variable command via wrapper: $firstBasename"
            }
            if ($remaining -match '^\$[A-Z_]') {
                return "Variable as command via wrapper: $firstBasename `$..."
            }
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($Command)) {
    return @{ Allowed = $true; Reason = "Empty command" } | ConvertTo-Json -Compress
}

$result = Test-VariableCommand -Cmd $Command -AllowVars $AllowVariableCommands

if ($result) {
    @{ Allowed = $false; Reason = $result } | ConvertTo-Json -Compress
} else {
    @{ Allowed = $true; Reason = "No variable command execution detected" } | ConvertTo-Json -Compress
}