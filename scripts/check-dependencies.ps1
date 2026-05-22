<#
.SYNOPSIS
    Reads all agent YAML manifests and detects dependency cycles.
.DESCRIPTION
    Scans agents/*.yaml, parses `dependencies` fields, builds a directed graph,
    and runs DFS cycle detection. Also flags missing agents, self-dependencies,
    and excessive dependency counts.
.EXAMPLE
    .\check-dependencies.ps1
.NOTES
    Exit 0 = clean, Exit 1 = errors found.
#>

$ErrorActionPreference = 'Stop'
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $MyInvocation.MyCommand.Path -Parent }
$agentsDir = Join-Path $ScriptRoot '..\agents'
$agentsDir = [System.IO.Path]::GetFullPath($agentsDir)

if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
    Write-Host "ERROR: Agents directory not found: $agentsDir" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# 1. PARSE ALL AGENT YAML FILES
# ------------------------------------------------------------------

# Simple YAML list parser: given lines array and start index, return list items
function Parse-YamlList($lines, [ref]$index) {
    $items = @()
    while ($index.Value -lt $lines.Count) {
        $line = $lines[$index.Value]
        if ($line -match '^\s*-\s*(.+)$') {
            $val = $Matches[1].Trim() -replace '^["'']|["'']$', ''
            if ($val) { $items += $val }
            $index.Value++
        }
        elseif ($line -match '^\s*\[\s*\]') {
            # Empty inline list: "dependencies: []"
            $index.Value++
            break
        }
        elseif ($line -match '^\S') {
            # Next top-level key -- list ended
            break
        }
        else {
            $index.Value++
        }
    }
    return $items
}

# Parse a single agent YAML file, return PSCustomObject with Name and Dependencies
function Parse-AgentFile($filePath) {
    $lines = Get-Content -LiteralPath $filePath -Encoding UTF8
    $name = $null
    $deps = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^name:\s*(.+)$') {
            $raw = $Matches[1].Trim()
            $name = $raw -replace '^["'']|["'']$', ''
            continue
        }

        if ($line -match '^dependencies:') {
            if ($line -match '\[\s*\]') {
                $deps = @()
            }
            else {
                $j = $i + 1
                $deps = Parse-YamlList $lines ([ref]$j)
            }
            continue
        }
    }

    return [PSCustomObject]@{ Name = $name; Dependencies = $deps }
}

$agentFiles = Get-ChildItem -LiteralPath $agentsDir -Filter '*.yaml' | Where-Object {
    $_.Name -ne 'agent-schema.yaml'
}

$agents = @{}
foreach ($file in $agentFiles) {
    $agent = Parse-AgentFile $file.FullName
    if (-not $agent.Name) {
        Write-Host "WARNING: Skipping $($file.Name) -- no `name` field" -ForegroundColor Yellow
        continue
    }
    $agents[$agent.Name] = $agent.Dependencies
}

if ($agents.Count -eq 0) {
    Write-Host "ERROR: No valid agent manifests found in $agentsDir" -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# 2. REPORT THE GRAPH
# ------------------------------------------------------------------
Write-Host "`n=== Agent Dependency Graph ===" -ForegroundColor Cyan

foreach ($name in ($agents.Keys | Sort-Object)) {
    $deps = $agents[$name]
    if ($deps.Count -eq 0) {
        Write-Host "$name -> (no dependencies)"
    }
    else {
        Write-Host "$name -> $($deps -join ', ')"
    }
}

# ------------------------------------------------------------------
# 3. PRELIMINARY CHECKS
# ------------------------------------------------------------------
Write-Host "`n=== Checking... ===" -ForegroundColor Cyan

$errorCount = 0

# 3a. Self-dependency check
$selfFound = $false
foreach ($name in $agents.Keys) {
    if ($name -in $agents[$name]) {
        if (-not $selfFound) { Write-Host "Self-dependencies:" }
        Write-Host "  [FAIL] $name depends on itself" -ForegroundColor Red
        $selfFound = $true
        $errorCount++
    }
}
if (-not $selfFound) {
    Write-Host "[PASS] No self-dependencies" -ForegroundColor Green
}

# 3b. Non-existent agent references
$missingFound = $false
foreach ($name in $agents.Keys) {
    foreach ($dep in $agents[$name]) {
        if ($dep -notin $agents.Keys) {
            if (-not $missingFound) { Write-Host "Non-existent references:" }
            Write-Host "  [FAIL] $name depends on '$dep' which does not exist" -ForegroundColor Red
            $missingFound = $true
            $errorCount++
        }
    }
}
if (-not $missingFound) {
    Write-Host "[PASS] All dependencies reference existing agents" -ForegroundColor Green
}

# 3c. Excessive dependencies (>5)
$heavyFound = $false
foreach ($name in $agents.Keys) {
    $count = $agents[$name].Count
    if ($count -gt 5) {
        if (-not $heavyFound) { Write-Host "Excessive dependencies (>5):" }
        Write-Host "  [WARN] $name has $count dependencies (threshold: 5)" -ForegroundColor Yellow
        $heavyFound = $true
    }
}
if (-not $heavyFound) {
    Write-Host "[PASS] All agents have 5 or fewer dependencies" -ForegroundColor Green
}

# ------------------------------------------------------------------
# 4. CYCLE DETECTION (DFS with recursion stack)
# ------------------------------------------------------------------

$WHITE = 0  # unvisited
$GRAY  = 1  # in current recursion stack
$BLACK = 2  # fully processed

$color = @{}
foreach ($node in $agents.Keys) { $color[$node] = $WHITE }

# Use script-scoped variables so inner function can signal results upward
$script:cycleFound = $false
$script:cyclePath  = $null

function dfs_visit($node, $stack) {
    $script:color[$node] = $script:GRAY
    [void]$stack.Add($node)

    foreach ($dep in $script:agents[$node]) {
        if ($dep -notin $script:agents.Keys) { continue }

        $depColor = $script:color[$dep]

        if ($depColor -eq $script:GRAY) {
            # Cycle found -- extract cycle segment from stack
            $startIdx = $stack.IndexOf($dep)
            if ($startIdx -ge 0) {
                $segments = $stack[$startIdx..($stack.Count - 1)]
                $script:cyclePath = ($segments -join ' -> ') + ' -> ' + $dep
            }
            $script:cycleFound = $true
            return
        }

        if ($depColor -eq $script:WHITE) {
            dfs_visit $dep $stack
            if ($script:cycleFound) { return }
        }
    }

    [void]$stack.RemoveAt($stack.Count - 1)
    $script:color[$node] = $script:BLACK
}

$stack = New-Object System.Collections.Generic.List[string]
foreach ($node in ($agents.Keys | Sort-Object)) {
    if ($color[$node] -eq $WHITE) {
        $stack.Clear()
        dfs_visit $node $stack
        if ($script:cycleFound) { break }
    }
}

if ($script:cycleFound) {
    Write-Host "[FAIL] Cycle found: $script:cyclePath" -ForegroundColor Red
    $errorCount++
}
else {
    Write-Host "[PASS] No cycles detected" -ForegroundColor Green
}

# ------------------------------------------------------------------
# 5. FINAL SUMMARY
# ------------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($errorCount -eq 0) {
    Write-Host "[PASS] All checks passed. Dependency graph is clean." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAIL] $errorCount error(s) found. Fix before proceeding." -ForegroundColor Red
    exit 1
}
