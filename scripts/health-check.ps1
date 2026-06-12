# health-check.ps1
# Comprehensive runtime health check for OpenCode config
# Run: powershell scripts/health-check.ps1

$ErrorActionPreference = "Continue"
$configDir = "$env:USERPROFILE\.config\opencode"
$memoryDir = "$configDir\memory"
$gatesDir = "$configDir\gates"
$libDir = "$configDir\lib"
$pluginsDir = "$configDir\plugins"

$results = @()
$pass = 0
$fail = 0
$warn = 0

function Check {
    param([string]$Name, [string]$Status, [string]$Detail = "")
    $script:results += [PSCustomObject]@{
        Name = $Name
        Status = $Status
        Detail = $Detail
    }
    switch ($Status) {
        "PASS" { $script:pass++ }
        "FAIL" { $script:fail++ }
        "WARN" { $script:warn++ }
    }
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    if ($Detail) {
        Write-Host "  [$Status] $Name - $Detail" -ForegroundColor $color
    } else {
        Write-Host "  [$Status] $Name" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "=== OpenCode Runtime Health Check ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "1. Config Validators" -ForegroundColor White
$vdOut = powershell -File "$configDir\scripts\validate-definitive.ps1" 2>&1 | Out-String
if ($vdOut -match "PASS: definitive OpenCode config validated") {
    Check "validate-definitive.ps1" "PASS"
} else {
    Check "validate-definitive.ps1" "FAIL" $vdOut.Substring(0, [Math]::Min(150, $vdOut.Length))
}

$vcOut = powershell -File "$configDir\scripts\validate-config.ps1" 2>&1 | Out-String
if ($vcOut -match "CONFIG INTEGRITY OK") {
    $stats = ($vcOut | Select-String "PASS: (\d+)").Matches.Groups[1].Value
    $fails = ($vcOut | Select-String "FAIL: (\d+)").Matches.Groups[1].Value
    Check "validate-config.ps1" "PASS" "$stats PASS, $fails FAIL"
} else {
    Check "validate-config.ps1" "FAIL"
}

Write-Host ""
Write-Host "2. Plugins (registered in opencode.json)" -ForegroundColor White
$opencodeJson = Get-Content "$configDir\opencode.json" -Raw | ConvertFrom-Json
$registeredPlugins = $opencodeJson.plugin
foreach ($pluginPath in $registeredPlugins) {
    $name = Split-Path $pluginPath -Leaf
    if (Test-Path $pluginPath) {
        $size = (Get-Item $pluginPath).Length
        Check "Plugin: $name" "PASS" "$size bytes"
    } else {
        Check "Plugin: $name" "FAIL" "File not found: $pluginPath"
    }
}

Write-Host ""
Write-Host "3. Plugin Init Markers" -ForegroundColor White
$loadFile = "$gatesDir\.memory-bridge-load.txt"
if (Test-Path $loadFile) {
    $loads = Get-Content $loadFile
    $count = $loads.Count
    Check "memory-bridge loads" "PASS" "$count load events recorded"
} else {
    Check "memory-bridge loads" "FAIL" "Marker file not found"
}

$gateMarker = "$gatesDir\.gate-system-init.marker"
if (Test-Path $gateMarker) {
    $content = Get-Content $gateMarker -Raw
    if ($content -match "initialized") {
        Check "gate-system.js init" "PASS"
    } else {
        Check "gate-system.js init" "WARN" "Marker exists but content unexpected"
    }
} else {
    Check "gate-system.js init" "WARN" "Marker not created (may be first run)"
}

Write-Host ""
Write-Host "4. Memory System" -ForegroundColor White

$counterFile = "$gatesDir\.task-counter.json"
if (Test-Path $counterFile) {
    $counter = Get-Content $counterFile -Raw | ConvertFrom-Json
    Check "Task counter" "PASS" "count=$($counter.count)"
} else {
    Check "Task counter" "WARN" "Not yet created (no idle events)"
}

$autoMemLog = "$memoryDir\auto-memory.log"
if (Test-Path $autoMemLog) {
    $size = (Get-Item $autoMemLog).Length
    $lines = (Get-Content $autoMemLog).Count
    $lastLine = Get-Content $autoMemLog -Tail 1
    Check "auto-memory.log" "PASS" "$lines entries"
} else {
    Check "auto-memory.log" "FAIL" "File not found"
}

$gateLog = "$memoryDir\gate-system.log"
if (Test-Path $gateLog) {
    $size = (Get-Item $gateLog).Length
    Check "gate-system.log" "PASS" "$size bytes"
    $recentFails = Select-String -Path $gateLog -Pattern "FAILED" | Select-Object -Last 5
    if ($recentFails.Count -gt 0) {
        $recentTime = $recentFails[-1].Line.Substring(0, 30)
        Check "Recent auto-memory failures" "WARN" "$($recentFails.Count) failures, latest: $recentTime"
    } else {
        Check "Recent auto-memory failures" "PASS" "none"
    }
} else {
    Check "gate-system.log" "FAIL" "Not created"
}

Write-Host ""
Write-Host "5. Graph Memory" -ForegroundColor White
$nodesDir = "$memoryDir\graph\nodes"
$edgesDir = "$memoryDir\graph\edges"
if (Test-Path $nodesDir) {
    $nodeCount = (Get-ChildItem $nodesDir).Count
    Check "Graph nodes dir" "PASS" "$nodeCount files"
} else {
    Check "Graph nodes dir" "FAIL" "Directory missing"
}
if (Test-Path $edgesDir) {
    $edgeCount = (Get-ChildItem $edgesDir).Count
    Check "Graph edges dir" "PASS" "$edgeCount files"
} else {
    Check "Graph edges dir" "FAIL" "Directory missing"
}

Write-Host ""
Write-Host "6. CASS Index" -ForegroundColor White
$cassIndex = "$memoryDir\cass\index.jsonl"
if (Test-Path $cassIndex) {
    $size = (Get-Item $cassIndex).Length
    $lines = (Get-Content $cassIndex).Count
    Check "CASS index.jsonl" "PASS" "$lines entries, $([math]::Round($size/1024, 1))KB"
} else {
    Check "CASS index.jsonl" "WARN" "Not created yet"
}

Write-Host ""
Write-Host "7. Skills" -ForegroundColor White
$skillCount = (Get-ChildItem "$configDir\skills" -Directory | Where-Object { $_.Name -ne ".archive" }).Count
Check "Active skills" "PASS" "$skillCount skills loaded"

Write-Host ""
Write-Host "8. MCP Servers" -ForegroundColor White
foreach ($mcpName in $opencodeJson.mcp.PSObject.Properties.Name) {
    $mcp = $opencodeJson.mcp.$mcpName
    if ($mcp.enabled -eq $true) {
        $type = $mcp.type
        Check "MCP: $mcpName" "PASS" "type=$type, enabled"
    } else {
        Check "MCP: $mcpName" "WARN" "disabled"
    }
}

Write-Host ""
Write-Host "9. Swarm System (CrewAI)" -ForegroundColor White
$crewFactory = "$libDir\agents\crew_factory.py"
$langgraphCoord = "$libDir\workflows\langgraph_coordinator.py"
$swarmPy = "$libDir\swarm.py"

if (Test-Path $crewFactory) {
    Check "crew_factory.py" "PASS" "$((Get-Item $crewFactory).Length) bytes"
} else {
    Check "crew_factory.py" "FAIL"
}
if (Test-Path $langgraphCoord) {
    Check "langgraph_coordinator.py" "PASS" "$((Get-Item $langgraphCoord).Length) bytes"
} else {
    Check "langgraph_coordinator.py" "FAIL"
}
if (Test-Path $swarmPy) {
    Check "swarm.py" "PASS" "$((Get-Item $swarmPy).Length) bytes"
} else {
    Check "swarm.py" "FAIL"
}

try {
    $swarmTest = python "$swarmPy" --help 2>&1
    if ($swarmTest -match "Usage:") {
        Check "Swarm CLI loads" "PASS"
    } else {
        Check "Swarm CLI loads" "WARN" $swarmTest.Substring(0, [Math]::Min(80, $swarmTest.Length))
    }
} catch {
    Check "Swarm CLI loads" "FAIL" $_.Exception.Message
}

Write-Host ""
Write-Host "10. Hook Scripts" -ForegroundColor White
$hookScripts = @(
    @{ Name = "hook-startup.ps1"; Path = "$configDir\scripts\hooks\hook-startup.ps1" },
    @{ Name = "on-stop.ps1"; Path = "$configDir\scripts\hooks\on-stop.ps1" },
    @{ Name = "post-edit.ps1"; Path = "$configDir\scripts\hooks\post-edit.ps1" },
    @{ Name = "pre-tool-check.ps1"; Path = "$configDir\scripts\hooks\pre-tool-check.ps1" },
    @{ Name = "post-tool-check.ps1"; Path = "$configDir\scripts\hooks\post-tool-check.ps1" },
    @{ Name = "auto-correction-capture.ps1"; Path = "$configDir\scripts\auto-correction-capture.ps1" },
    @{ Name = "rotate-session-log.ps1"; Path = "$configDir\scripts\rotate-session-log.ps1" }
)
foreach ($script in $hookScripts) {
    if (Test-Path $script.Path) {
        Check "Hook: $($script.Name)" "PASS"
    } else {
        Check "Hook: $($script.Name)" "FAIL" "File not found: $($script.Path)"
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  PASS: $pass" -ForegroundColor Green
Write-Host "  WARN: $warn" -ForegroundColor Yellow
Write-Host "  FAIL: $fail" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "Failed checks need attention. Run validators for details." -ForegroundColor Red
    Write-Host "  powershell scripts/validate-definitive.ps1" -ForegroundColor Gray
    Write-Host "  powershell scripts/validate-config.ps1" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "All systems nominal." -ForegroundColor Green
}
Write-Host ""
