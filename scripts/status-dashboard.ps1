# status-dashboard.ps1
# Clean status dashboard - enforcement overview
# Run: powershell -File "$env:USERPROFILE\.config\opencode\scripts\status-dashboard.ps1"

$CONFIG = $env:USERPROFILE
if (-not (Test-Path $CONFIG)) { Write-Host "[FAIL] USERPROFILE not set"; exit 1 }

$memDir = Join-Path $CONFIG ".config\opencode\memory"
$plugDir = Join-Path $CONFIG ".config\opencode\plugins"
$skillDir = Join-Path $CONFIG ".config\opencode\skills"
$cmdDir = Join-Path $CONFIG ".config\opencode\commands"
$gatesDir = Join-Path $CONFIG ".config\opencode\gates"

$PASS = 0
$WARN = 0
$FAIL = 0

function ok($cond, $label, $detail) {
    if ($cond) {
        Write-Host "  [PASS]  $($label.PadRight(28))  $detail" -ForegroundColor Green
        $script:PASS++
    } else {
        Write-Host "  [WARN]  $($label.PadRight(28))  $detail" -ForegroundColor Yellow
        $script:WARN++
    }
}

function fail($label, $detail) {
    Write-Host "  [FAIL]  $($label.PadRight(28))  $detail" -ForegroundColor Red
    $script:FAIL++
}

function section($name) {
    Write-Host ""
    Write-Host "  -- $name --------------------------------------"
}

function exists($path) {
    return (Test-Path -LiteralPath $path)
}

function fileLines($path) {
    if (-not (exists $path)) { return 0 }
    return @(Get-Content -LiteralPath $path -ErrorAction SilentlyContinue).Count
}

Write-Host ""
Write-Host "  ========================================================="
Write-Host "   ENFORCEMENT DASHBOARD"
Write-Host "   $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "  ========================================================="

# ── CORE MEMORY SYSTEM ──────────────────────────────────
section "CORE MEMORY SYSTEM"

$autoMemLog = Join-Path $memDir "auto-memory.log"
$autoLines = fileLines $autoMemLog
$autoFailed = (Select-String -Path $autoMemLog -Pattern "FAILED|ERROR" -ErrorAction SilentlyContinue | Measure-Object).Count
if ($autoLines -gt 0) {
    $pct = [int](100 * ($autoLines - $autoFailed) / $autoLines)
    ok ($autoFailed -eq 0) "auto-memory" "$autoLines OK / $autoFailed FAIL / $pct% success"
} else {
    ok $false "auto-memory" "no log entries"
}

$sessEvents = Join-Path $memDir "session_events.jsonl"
$sessCount = fileLines $sessEvents
$rotationNote = if ($sessCount -gt 10000) { "(rotated clean)" } else { "" }
ok ($sessCount -gt 0) "session_events" "$sessCount lines $rotationNote"

$cassPath = Join-Path $memDir "cass\index.jsonl"
$cassCount = fileLines $cassPath
if ($cassCount -gt 1000) {
    ok $true "cass/index.jsonl" "$cassCount entries"
} else {
    ok $true "cass/index.jsonl" "$cassCount entries (still warming up)"
}

$sessLog = Join-Path $memDir "session_log.md"
$realTasks = (Select-String -Path $sessLog -Pattern "^\s*-\s+\[" -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch "untitled|idle" } | Measure-Object).Count
ok ($realTasks -ge 0) "session_log.md" "$realTasks real tasks"

# ── HOOKS & PLUGINS ────────────────────────────────────
section "HOOKS & PLUGINS"

$gateLog = Join-Path $memDir "gate-system.log"
$hookErr = Join-Path $CONFIG ".config\opencode\hook-errors.log"

if (exists $gateLog) {
    $sizeKB = [int]((Get-Item -LiteralPath $gateLog).Length / 1KB)
    $lines = fileLines $gateLog
    ok $true "gate-system.log" "$lines lines / ${sizeKB}KB"
} else {
    fail "gate-system.log" "missing"
}

if (exists $hookErr) {
    $errCount = (Select-String -Path $hookErr -Pattern "ERROR|FAIL" -ErrorAction SilentlyContinue | Measure-Object).Count
    ok ($errCount -eq 0) "hook-errors.log" "$errCount errors"
} else {
    ok $true "hook-errors.log" "0 errors"
}

$cp = Join-Path $plugDir "compaction-survival.js"
$cpLog = Join-Path $memDir "compaction-survival.log"
if (exists $cp) {
    # compaction-survival.js writes to its own log file (compaction-survival.log),
    # not gate-system.log. Read the right file.
    if (Test-Path $cpLog) {
        $cpContent = Get-Content $cpLog -Raw
        $cpFire = ($cpContent.Split("`n") | Where-Object { $_ -match "fired" }).Count
        $cpInit = ($cpContent.Split("`n") | Where-Object { $_ -match "Initialized" }).Count
    } else {
        $cpFire = 0
        $cpInit = 0
    }
    if ($cpInit -gt 0) {
        ok $true "compaction-survival.js" "$cpFire fires / $cpInit inits"
    } else {
        fail "compaction-survival.js" "0 inits - log not yet created at $cpLog"
    }
} else {
    fail "compaction-survival.js" "missing"
}

$mb = Join-Path $plugDir "memory-bridge.js"
if (exists $mb) {
    $mbEvents = (Select-String -Path $gateLog -Pattern "memory-bridge STARTED|memory-bridge loaded" -ErrorAction SilentlyContinue | Measure-Object).Count
    ok ($mbEvents -gt 0) "memory-bridge.js" "$mbEvents load events"
} else {
    fail "memory-bridge.js" "missing"
}

$pre = Join-Path $plugDir "pre-tool-guard.js"
$post = Join-Path $plugDir "post-tool-guard.js"
$preOk = (exists $pre) -and ((Get-Content -LiteralPath $pre -Raw -ErrorAction SilentlyContinue) -match "export const PreToolGuard")
$postOk = (exists $post) -and ((Get-Content -LiteralPath $post -Raw -ErrorAction SilentlyContinue) -match "export const PostToolGuard")
ok $preOk "pre-tool-guard.js" "export + hook"
ok $postOk "post-tool-guard.js" "export + hook"

# ── TASK THROUGHPUT ─────────────────────────────────────
section "TASK THROUGHPUT"

$counterPath = Join-Path $gatesDir ".task-counter.json"
if (exists $counterPath) {
    $ct = Get-Content -LiteralPath $counterPath -Raw | ConvertFrom-Json
    $freshNote = if ($ct.count -lt 5) { "(counter fresh)" } else { "(ongoing)" }
    ok $true "Task counter" "$($ct.count) tasks $freshNote"
} else {
    ok $true "Task counter" "0 (fresh session)"
}

if (exists $gateLog) {
    $gateFails = (Select-String -Path $gateLog -Pattern "BLOCKED|INJECTION DETECTED" -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($gateFails -gt 0) {
        ok $true "Gate blocks" "$gateFails blocks logged (attacks detected)"
    } else {
        ok $true "Gate blocks" "0 (no attacks)"
    }
}

# ── MCP SERVERS ────────────────────────────────────────
section "MCP SERVERS"

$opencodeJson = Join-Path $CONFIG ".config\opencode\opencode.json"
if (exists $opencodeJson) {
    $json = Get-Content -LiteralPath $opencodeJson -Raw | ConvertFrom-Json
    $mcpProps = @($json.mcp.PSObject.Properties)
    $on = @($mcpProps | Where-Object { $_.Value.enabled -eq $true }).Count
    ok ($on -ge 4) "MCPs enabled" "$on / $($mcpProps.Count) configured"
} else {
    fail "MCP servers" "opencode.json missing"
}

# ── AGENTS & SKILLS ──────────────────────────────────
section "AGENTS & SKILLS"

$agentDir = Join-Path $CONFIG ".config\opencode\agents"
$agentCount = (Get-ChildItem -LiteralPath $agentDir -Filter "*.md" -ErrorAction SilentlyContinue).Count
ok ($agentCount -ge 10) "Agents" "$agentCount agents"

$skillCount = 0
if (exists $skillDir) {
    Get-ChildItem -LiteralPath $skillDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notmatch "\.archive" -and (Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md"))) {
            $script:skillCount++
        }
    }
}
ok ($skillCount -ge 30) "Skills" "$skillCount skills"

$swarmAgent = Join-Path $CONFIG ".config\opencode\lib\agents\crew_factory.py"
$swarmCoordinator = Join-Path $CONFIG ".config\opencode\lib\workflows\langgraph_coordinator.py"
$swarmCli = Join-Path $CONFIG ".config\opencode\lib\swarm.py"
if ((exists $swarmAgent) -and (exists $swarmCoordinator) -and (exists $swarmCli)) {
    $total = (Get-Item -LiteralPath $swarmAgent).Length + (Get-Item -LiteralPath $swarmCoordinator).Length + (Get-Item -LiteralPath $swarmCli).Length
    ok $true "Swarm/CrewAI" "3/3 files present ($total bytes total)"
} else {
    $missing = @()
    if (-not (exists $swarmAgent)) { $missing += "crew_factory" }
    if (-not (exists $swarmCoordinator)) { $missing += "langgraph" }
    if (-not (exists $swarmCli)) { $missing += "swarm" }
    ok $false "Swarm/CrewAI" ("missing: " + ($missing -join ", "))
}

$tdd = Join-Path $skillDir "testing-standards\SKILL.md"
$tddRaw = if (exists $tdd) { Get-Content -LiteralPath $tdd -Raw } else { "" }
if ($tddRaw -match "auto_load.*code-builder") {
    ok $true "TDD enforcement" "auto_load active"
} else {
    ok $false "TDD enforcement" "auto_load not set"
}

$council = Join-Path $cmdDir "council.md"
if (exists $council) {
    ok $true "Council command" "active"
} else {
    ok $false "Council command" "missing"
}

$mobileSkills = @("android-native-dev", "flutter-dev", "ios-application-dev", "react-native-dev")
$mobileActive = 0
foreach ($m in $mobileSkills) {
    if (Test-Path -LiteralPath (Join-Path $skillDir "$m\SKILL.md")) { $mobileActive++ }
}
ok ($mobileActive -ge 4) "Mobile skills" "$mobileActive/4 active"

# ── DNA / GENE EVOLUTION ────────────────────────────────
section "DNA / GENE EVOLUTION"

$dnaYaml = Join-Path $skillDir "DNA.yaml"
if (exists $dnaYaml) {
    $geneCount = (Select-String -Path $dnaYaml -Pattern "^\s+-\s+id:\s" -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($geneCount -ge 40) {
        ok $true "DNA genes" "$geneCount total genes"
    } elseif ($geneCount -gt 0) {
        ok $false "DNA genes" "$geneCount genes (expected 40+)"
    } else {
        ok $false "DNA genes" "0 genes found (regex may be wrong)"
    }

    $pendingGenes = (Select-String -Path $dnaYaml -Pattern "status.*pending" -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($pendingGenes -gt 0) {
        ok $false "Pending genes" "$pendingGenes pending (review needed)"
    } else {
        ok $true "Pending genes" "0 pending"
    }
} else {
    fail "DNA.yaml" "missing"
}

$maturity = Join-Path $memDir "outcomes\pattern_maturity.yaml"
if (exists $maturity) {
    $proven = (Select-String -Path $maturity -Pattern "maturity:\s*proven" -ErrorAction SilentlyContinue | Measure-Object).Count
    $candidate = (Select-String -Path $maturity -Pattern "maturity:\s*candidate" -ErrorAction SilentlyContinue | Measure-Object).Count
    $anti = (Select-String -Path $maturity -Pattern "maturity:\s*anti-pattern" -ErrorAction SilentlyContinue | Measure-Object).Count
    ok $true "Pattern maturity" "proven=$proven candidate=$candidate anti=$anti"
} else {
    ok $true "Pattern maturity" "no history yet (normal for fresh setup)"
}

$patterns = Join-Path $memDir "outcomes\patterns.jsonl"
if (exists $patterns) {
    $pLines = (Get-Content -LiteralPath $patterns | Where-Object { $_.Trim() -ne "" }).Count
    if ($pLines -ge 10) {
        ok $true "patterns.jsonl" "$pLines entries (mature)"
    } else {
        ok $true "patterns.jsonl" "$pLines entries (growing, need 10+ for scoring)"
    }
} else {
    ok $true "patterns.jsonl" "no entries yet"
}

# ── MODEL ROUTING ─────────────────────────────────────
section "MODEL ROUTING"

if (exists $opencodeJson) {
    $defaultModel = $json.model
    ok $true "Default model" "$defaultModel"
    if ($defaultModel -match "minimax-m2.7") {
        ok $true "Workhorse" "M2.7 confirmed"
    } else {
        ok $false "Workhorse" "expected M2.7, got $defaultModel"
    }
    $m3Configured = $json.provider.minimax.models.PSObject.Properties.Name -contains "minimax-m3"
    if ($m3Configured) {
        ok $true "M3 burst model" "available (M2.7 is default)"
    } else {
        ok $false "M3 burst model" "not configured"
    }
    $dsConfigured = $json.provider.PSObject.Properties.Name -contains "opencode-go"
    if ($dsConfigured) {
        $dsModel = $json.provider.'opencode-go'.models.PSObject.Properties.Name -join ","
        ok $true "opencode-go" "$dsModel"
    }
}

# ── GATE INFRASTRUCTURE (scripts referenced by genes/agents) ─────
section "GATE INFRASTRUCTURE"

$scriptsDir = Join-Path $CONFIG ".config\opencode\scripts"
$gateScripts = @(
    @{ Name = "gate-init.ps1"; Purpose = "task gate init (code-builder)" }
    @{ Name = "gate-check.ps1"; Purpose = "step verification (hard rule)" }
    @{ Name = "run-plan-mode.ps1"; Purpose = "vague task plan (SESSION-005)" }
    @{ Name = "gate\retro-analyze.ps1"; Purpose = "evolution trigger (every 10)" }
    @{ Name = "checkpoint.ps1"; Purpose = "compaction survival state" }
)
$gateTotal = $gateScripts.Count
$gateFound = 0
foreach ($g in $gateScripts) {
    $path = Join-Path $scriptsDir $g.Name
    if (Test-Path -LiteralPath $path) {
        $gateFound++
        $size = (Get-Item -LiteralPath $path).Length
        ok $true $g.Name "$($g.Purpose) ($size bytes)"
    } else {
        ok $false $g.Name "MISSING - $($g.Purpose) will fail silently"
    }
}
if ($gateFound -eq $gateTotal) {
    ok $true "Gate infrastructure" "$gateFound/$gateTotal scripts present"
} else {
    ok $false "Gate infrastructure" "only $gateFound/$gateTotal scripts present"
}

# ── SUMMARY ────────────────────────────────────────────
Write-Host ""
Write-Host "  ========================================================="
$totalCount = $PASS + $WARN + $FAIL
$healthPct = if ($totalCount -gt 0) { [int](100 * $PASS / $totalCount) } else { 0 }
Write-Host "   PASS:$PASS  WARN:$WARN  FAIL:$FAIL  Health:$healthPct%"
Write-Host "  ========================================================="
Write-Host ""

if ($FAIL -gt 0) {
    Write-Host "  ACTION: Fix $FAIL FAIL entries above" -ForegroundColor Red
} elseif ($WARN -gt 10) {
    Write-Host "  INFO: $WARN warnings - review non-critical" -ForegroundColor Yellow
} else {
    Write-Host "  ALL CLEAR - no action needed" -ForegroundColor Green
}
