#!/usr/bin/env pwsh
# security-scan.ps1
# Local security scanner for OpenCode configuration
# Pattern inspired by AgentShield (github.com/affaan-m/agentshield)
# Scans: opencode.json perms, MCP configs, skill content, hook scripts
# Usage: pwsh security-scan.ps1 [-ConfigRoot <path>] [-Log] [-FailOn <severity>]
# Exit 0 = clean, Exit 1 = findings above threshold

param(
    [string]$ConfigRoot = $env:OPENCODE_CONFIG_HOME,
    [switch]$Log,
    [ValidateSet("info","low","medium","high","critical")]
    [string]$FailOn = "high"
)

if (-not $ConfigRoot) {
    $ConfigRoot = Join-Path $env:USERPROFILE ".config\opencode"
}

$findings = @()
$scanLog = Join-Path $ConfigRoot "memory\security-scan.log"

function Add-Finding {
    param([string]$Severity, [string]$Category, [string]$Path, [string]$Message)
    $script:findings += [PSCustomObject]@{
        ts = (Get-Date -Format "o")
        severity = $Severity
        category = $Category
        path = $Path
        message = $Message
    }
}

# Scan 1: opencode.json for over-permissive settings
$opencodeJson = Join-Path $ConfigRoot "opencode.json"
if (Test-Path $opencodeJson) {
    try {
        $cfg = Get-Content $opencodeJson -Raw | ConvertFrom-Json
        $dangerousPerms = @('repo_overview', 'external_directory', 'doom_loop', 'webfetch')
        foreach ($perm in $dangerousPerms) {
            if ($cfg.permission.$perm -eq 'allow') {
                Add-Finding "info" "permissions" "opencode.json" "permission '$perm' is set to allow (verify this is intentional)"
            }
        }
    } catch {
        Add-Finding "medium" "config" $opencodeJson "Failed to parse opencode.json: $_"
    }
}

# Scan 2: MCP server configs for exposed secrets
$mcpFiles = Get-ChildItem -Path $ConfigRoot -Recurse -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -match 'mcp' -or $_.FullName -match 'opencode\.json'
}
$secretPatterns = @(
    @{ p = 'sk-[A-Za-z0-9]{20,}'; desc = 'OpenAI API key' },
    @{ p = 'sk-or-[A-Za-z0-9-]{20,}'; desc = 'OpenRouter API key' },
    @{ p = 'ghp_[A-Za-z0-9]{36}'; desc = 'GitHub PAT' },
    @{ p = 'glpat-[A-Za-z0-9_-]{20,}'; desc = 'GitLab PAT' },
    @{ p = 'xoxb-[A-Za-z0-9-]{20,}'; desc = 'Slack bot token' },
    @{ p = 'AIza[A-Za-z0-9_-]{35}'; desc = 'Google API key' },
    @{ p = 'AKIA[A-Z0-9]{16}'; desc = 'AWS access key' }
)
foreach ($f in $mcpFiles) {
    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($sp in $secretPatterns) {
        if ($content -match $sp.p) {
            Add-Finding "critical" "mcp-secret" $f.FullName "Hardcoded $($sp.desc) detected"
        }
    }
}

# Scan 3: skills/ for suspicious content patterns
$skillsDir = Join-Path $ConfigRoot "skills"
if (Test-Path $skillsDir) {
    $suspiciousPatterns = @(
        @{ p = 'eval\s*\(\s*atob'; desc = 'Base64 eval (potential RCE)' },
        @{ p = 'powershell\s+-enc\s+[A-Za-z0-9+/=]{50,}'; desc = 'Encoded PowerShell payload' },
        @{ p = 'child_process\.exec\s*\('; desc = 'Shell exec from skill (review required)' }
    )
    Get-ChildItem -Path $skillsDir -Recurse -Filter "*.js" -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        foreach ($sp in $suspiciousPatterns) {
            if ($content -match $sp.p) {
                Add-Finding "high" "skill-content" $_.FullName "$($sp.desc) found in skill file"
            }
        }
    }
}

# Scan 4: plugin scripts for shell injection surfaces
$pluginDir = Join-Path $ConfigRoot "plugins"
if (Test-Path $pluginDir) {
    $injectionPatterns = @(
        @{ p = 'execSync\s*\(\s*[`''"]\s*\$'; desc = 'Unescaped template in execSync' },
        @{ p = 'exec\s*\(\s*[`''"]\s*\$\{'; desc = 'String interpolation in shell exec' }
    )
    Get-ChildItem -Path $pluginDir -Filter "*.js" -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        foreach ($ip in $injectionPatterns) {
            if ($content -match $ip.p) {
                Add-Finding "medium" "plugin-injection" $_.FullName "$($ip.desc) -- review required"
            }
        }
    }
}

# Report
$severityOrder = @{ 'critical' = 4; 'high' = 3; 'medium' = 2; 'low' = 1; 'info' = 0 }
$findings = $findings | Sort-Object -Property @{Expression={$severityOrder[$_.severity]}; Descending=$true}

if ($Log -or $findings.Count -gt 0) {
    $logLine = "[$(Get-Date -Format 'o')] scan completed: $($findings.Count) findings"
    Add-Content -Path $scanLog -Value $logLine -ErrorAction SilentlyContinue
    foreach ($f in $findings) {
        $line = "[$($f.severity.ToUpper())] $($f.category) $($f.path) -- $($f.message)"
        Add-Content -Path $scanLog -Value $line -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "=== SECURITY SCAN RESULTS ===" -ForegroundColor Cyan
Write-Host "Config root: $ConfigRoot"
Write-Host "Findings: $($findings.Count)"
Write-Host ""

if ($findings.Count -gt 0) {
    foreach ($f in $findings) {
        $color = switch ($f.severity) {
            'critical' { 'Red' }
            'high'     { 'Red' }
            'medium'   { 'Yellow' }
            'low'      { 'Gray' }
            default    { 'Gray' }
        }
        Write-Host "[$($f.severity.ToUpper())] " -ForegroundColor $color -NoNewline
        Write-Host "$($f.category) " -NoNewline
        Write-Host "$($f.path)" -NoNewline
        Write-Host " -- $($f.message)"
    }
} else {
    Write-Host "No issues found." -ForegroundColor Green
}

# Decide exit code based on FailOn threshold
$threshold = $severityOrder[$FailOn]
$maxSeverity = ($findings | ForEach-Object { $severityOrder[$_.severity] } | Measure-Object -Maximum).Maximum
if ($maxSeverity -ge $threshold) {
    Write-Host ""
    Write-Host "FAIL: findings at or above '$FailOn' severity detected." -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "PASS: no findings at or above '$FailOn' severity." -ForegroundColor Green
exit 0
