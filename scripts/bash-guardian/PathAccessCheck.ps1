# PathAccessCheck.ps1
# SP-3: External path access control with balance check
# Blocks access to paths outside project root unless from allowed read/copy commands

param(
    [string]$Command = "",
    [string]$ProjectRoot = "",
    [switch]$AllowExternalPathAccess
)

$ErrorActionPreference = "SilentlyContinue"

# Special /dev files always allowed
$allowedDevFiles = @('/dev/null', '/dev/stdout', '/dev/stderr', '/dev/stdin', '/dev/zero', '/dev/urandom', '/dev/random', '/dev/tty')

# Commands that can read from external paths (read-only, no write)
$readExceptionCommands = @('cd', 'ls', 'cat', 'less', 'more', 'head', 'tail', 'grep', 'rg', 'find', 'file', 'stat', 'wc', 'diff', 'tree', 'readlink', 'which', 'dirname', 'basename')

# Commands that can copy FROM external paths (source paths not counted)
$copyExceptionCommands = @('cp', 'ln', 'rsync')

function Get-ProjectRoot {
    if ($ProjectRoot -and (Test-Path $ProjectRoot)) {
        return (Resolve-Path $ProjectRoot).Path
    }
    # Default to current directory
    return Get-Location
}

function Test-IsExternalPath {
    param([string]$Path, [string]$Project, [string]$WorkingDir)

    # Check allowed /dev files
    if ($allowedDevFiles -contains $Path) { return $false }
    if ($Path.StartsWith('/dev/fd/')) { return $false }

    try {
        $target = $Path
        if ($Path.StartsWith('~/')) {
            $target = [Environment]::ExpandEnvironmentVariables($Path)
        }
        $resolved = if ([System.IO.Path]::IsPathRooted($target)) {
            [System.IO.Path]::GetFullPath($target)
        } else {
            [System.IO.Path]::GetFullPath((Join-Path $WorkingDir $target))
        }

        # Check if inside project
        if ($resolved.StartsWith($Project)) { return $false }

        # Check if in /tmp (allowed)
        $tmpResolved = [System.IO.Path]::GetFullPath((Join-Path $WorkingDir "/tmp"))
        if ($resolved.StartsWith($tmpResolved)) { return $false }

        # Allow home directory references
        $homeDir = [Environment]::GetFolderPath('Home')
        if ($homeDir -and $resolved.StartsWith($homeDir)) { return $false }
        if ($resolved.StartsWith($env:USERPROFILE)) { return $false }

        return $true
    } catch {
        return $true  # On error, treat as external
    }
}

function Get-PathsFromCommand {
    param([string]$Cmd)

    $paths = @()
    $parts = $Cmd -split '\s+'

    foreach ($part in $parts) {
        # Skip flags
        if ($part.StartsWith('-')) { continue }
        # Skip variable expansions
        if ($part -match '^\$\{?') { continue }

        # Check for path-like strings
        if ($part -match '^(\.\.?/|\/|~/|\\\\|/[a-z]:)' -or $part -match '^[a-z]:[\\\/]') {
            $cleanPart = $part -replace '["'"'"']', ''
            if ($cleanPart) { $paths += $cleanPart }
        }
    }

    return $paths
}

function Test-PathAccess {
    param(
        [string]$Cmd,
        [string]$Project,
        [string]$WorkingDir,
        [bool]$AllowExternal
    )

    if ($AllowExternal) { return $null }

    $paths = Get-PathsFromCommand -Cmd $Cmd
    if ($paths.Count -eq 0) { return $null }

    $externalPaths = @()
    foreach ($p in $paths) {
        if (Test-IsExternalPath -Path $p -Project $Project -WorkingDir $WorkingDir) {
            $externalPaths += $p
        }
    }

    if ($externalPaths.Count -eq 0) { return $null }

    # Count allowed external accesses
    $parts = $Cmd -split '\s+'
    if ($parts.Count -eq 0) {
        return "External path access not allowed: $($externalPaths.Count) external path(s)"
    }

    $cmdName = $parts[0] -replace '.*[\\/]', ''

    # Read exceptions (cd, ls, cat, grep, etc.) - paths are inputs, allowed
    if ($readExceptionCommands -contains $cmdName) {
        # All external paths are inputs for read commands, allowed
        return $null
    }

    # Copy exceptions (cp, ln, rsync) - all except last are sources
    if ($copyExceptionCommands -contains $cmdName) {
        if ($parts.Count -ge 3) {
            # All args except first (cmd) and last (dest) are sources
            $sourceParts = $parts[1..($parts.Count - 2)]
            $externalSources = 0
            foreach ($sp in $sourceParts) {
                if (-not $sp.StartsWith('-')) {
                    if (Test-IsExternalPath -Path $sp -Project $Project -WorkingDir $WorkingDir) {
                        $externalSources++
                    }
                }
            }
            # Balance: external sources must not exceed external destinations
            $destExternal = 0
            $lastArg = $parts[-1]
            if (-not $lastArg.StartsWith('-') -and (Test-IsExternalPath -Path $lastArg -Project $Project -WorkingDir $WorkingDir)) {
                $destExternal = 1
            }
            if ($externalSources -le $destExternal) {
                return $null  # Balance satisfied
            }
        }
        return "External path copy balance not satisfied (sources > destinations)"
    }

    # Check if any path is external - this is the blocking case
    return "External path access not allowed. Allowed commands for external paths: READ: $($readExceptionCommands -join ', ') | COPY-FROM: $($copyExceptionCommands -join ', '). Copy external files to project directory or /tmp first."
}

if ([string]::IsNullOrWhiteSpace($Command)) {
    return @{ Allowed = $true; Reason = "Empty command" } | ConvertTo-Json -Compress
}

$projectRoot = Get-ProjectRoot
$workingDir = (Get-Location).Path

$result = Test-PathAccess -Cmd $Command -Project $projectRoot -WorkingDir $workingDir -AllowExternal $AllowExternalPathAccess

if ($result) {
    @{ Allowed = $false; Reason = $result } | ConvertTo-Json -Compress
} else {
    @{ Allowed = $true; Reason = "Path access allowed" } | ConvertTo-Json -Compress
}