# BlacklistCheck.ps1
# SP-3: Command blacklist check with wrapper scanning

param(
    [string]$Command = "",
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "SilentlyContinue"

# Default blacklist
$commandBlacklist = @(
    'sudo', 'su', 'passwd', 'chown',
    'eval', 'sh', 'bash', 'zsh', 'fish', 'exec',
    'git push', 'git reset --hard', 'git clean -fd',
    'docker run --privileged', 'docker exec --privileged', 'docker rm -f',
    'mkfs', 'fdisk', 'parted',
    'systemctl start', 'systemctl stop', 'systemctl restart',
    'service start', 'service stop'
)

$wrapperCommands = @('sudo', 'timeout', 'time', 'nice', 'nohup', 'strace', 'ltrace', 'env', 'watch', 'xargs', 'parallel', 'caffeinate', 'unbuffer', 'exec', 'eval', 'sh', 'bash', 'zsh')

# Load config if provided
if ($ConfigPath -and (Test-Path $ConfigPath)) {
    try {
        $yamlContent = Get-Content $ConfigPath -Raw
        # Parse blacklist entries
        $blkSection = [regex]::Match($yamlContent, 'command_blacklist:\s*\n((?:\s+-\s+.+\s*\n)+)').Value
        if ($blkSection) {
            $commandBlacklist = [regex]::Matches($blkSection, '(?<=-\s+).+?(?=\s*#|$)') | ForEach-Object { $_.Value.Trim() }
        }
        # Parse wrapper commands
        $wrapSection = [regex]::Match($yamlContent, 'wrapper_commands:\s*\n((?:\s+-\s+\w+\s*\n)+)').Value
        if ($wrapSection) {
            $wrapperCommands = [regex]::Matches($wrapSection, '(?<=-\s+)\w+') | ForEach-Object { $_.Value }
        }
    } catch {}
}

function Test-CommandBlacklist {
    param([string]$Cmd, [string[]]$Blacklist, [string[]]$Wrappers)

    $normalized = $Cmd.Trim()
    if (-not $normalized) { return $null }

    # Split into parts for analysis
    $parts = $normalized -split '\s+'
    if ($parts.Count -eq 0) { return $null }

    $firstCmd = $parts[0]

    foreach ($pattern in $Blacklist) {
        $patternParts = $pattern -split '\s+'
        $patternCmd = $patternParts[0]

        # Direct match
        if ($firstCmd -eq $patternCmd) {
            # Check if full pattern matches
            if ($patternParts.Count -eq 1) {
                return "Blacklisted command: $pattern"
            }
            # Check full pattern
            $remaining = $parts[1..($parts.Count - 1)] -join ' '
            $patternArgs = $patternParts[1..($patternParts.Count - 1)] -join ' '
            if ($remaining -match ("^" + [regex]::Escape($patternArgs))) {
                return "Blacklisted command pattern: $pattern"
            }
        }

        # Wrapper scanning: if first command is a wrapper, check if pattern appears elsewhere
        $firstBasename = if ($firstCmd -match '[\\/]') { $firstCmd -replace '.*[\\/]', '' } else { $firstCmd }
        if ($Wrappers -contains $firstBasename) {
            $remaining = $parts[1..($parts.Count - 1)] -join ' '
            # Pattern with args
            if ($patternParts.Count -gt 1) {
                $patCmd = $patternParts[0]
                $patArgs = $patternParts[1..($patternParts.Count - 1)] -join ' '
                if ($remaining -match ("^" + [regex]::Escape($patCmd) + "\s+" + [regex]::Escape($patArgs))) {
                    return "Blacklisted command via wrapper: $pattern"
                }
            } else {
                # Single word pattern - check if it appears as command
                if ($remaining -match ("^" + [regex]::Escape($pattern) + "\b")) {
                    return "Blacklisted command via wrapper: $pattern"
                }
            }
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($Command)) {
    return @{ Allowed = $true; Reason = "Empty command" } | ConvertTo-Json -Compress
}

$result = Test-CommandBlacklist -Cmd $Command -Blacklist $commandBlacklist -Wrappers $wrapperCommands

if ($result) {
    @{ Allowed = $false; Reason = $result } | ConvertTo-Json -Compress
} else {
    @{ Allowed = $true; Reason = "Command not on blacklist" } | ConvertTo-Json -Compress
}