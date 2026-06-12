# OPENCODE CONFIGURATION — FULL VERIFICATION PROMPT

Paste this into a FRESH OpenCode session to audit the entire configuration.

---

## VERIFICATION CHECKLIST

### 1. SESSION EVENTS (must be ≤10K lines after rotation)

```
session_events_lines = (Get-Content "$env:USERPROFILE\.config\opencode\memory\session_events.jsonl" | Measure-Object -Line).Lines
session_events_size_mb = [math]::Round((Get-Item "$env:USERPROFILE\.config\opencode\memory\session_events.jsonl").Length / 1MB, 2)
Write-Host "session_events: $session_events_lines lines, ${session_events_size_mb}MB"
```

**Expected:** ≤11,000 lines, ≤1MB. Will auto-rotate on first `session.deleted`.

---

### 2. SESSION-ENV (must be 0-5 dirs, auto-cleaned)

```
Get-ChildItem "$env:USERPROFILE\.claude\session-env" -Directory -EA SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
```

**Expected:** 0 dirs. Auto-cleaned on `session.deleted`.

---

### 3. PLAYWRIGHT_MCP_TOKEN (must be env var, NOT hardcoded)

```
# Check config — token should NOT appear
(Get-Content "$env:USERPROFILE\.config\opencode\opencode.json" -Raw) -match 'wd4wDbbAff0'

# Check env var IS set
[System.Environment]::GetEnvironmentVariable("PLAYWRIGHT_MCP_TOKEN", "User") | Substring 0 8
```

**Expected:** Token NOT in config, YES in env var.

---

### 4. SWARM.PY WORKFLOWS (must not crash)

```
python -c "import sys; sys.path.insert(0,'C:/Users/Windows/.config/opencode/lib'); from swarm import run_workflow; print(run_workflow('test'))"
```

**Expected:** `{"ok": true, ...}` with no LangGraph thread_id error.

---

### 5. SESSION YAML (must exist after fresh restart)

```
Test-Path "$env:USERPROFILE\.config\opencode\memory\session.yaml"
```

**Expected:** True. Created on session start.

---

### 6. PLUGINS LOADED (marker files exist)

```
Test-Path "$env:USERPROFILE\.config\opencode\gates\.memory-bridge-load.txt"
Test-Path "$env:USERPROFILE\.config\opencode\gates\.gate-system-init.marker"
```

**Expected:** Both True.

---

### 7. CASS INDEX (must exist and be healthy)

```
$cassSize = [math]::Round((Get-Item "$env:USERPROFILE\.config\opencode\memory\cass\index.jsonl").Length / 1MB, 2)
$cassLines = (Get-Content "$env:USERPROFILE\.config\opencode\memory\cass\index.jsonl" | Measure-Object -Line).Lines
Write-Host "CASS: ${cassSize}MB, $cassLines lines"
```

**Expected:** 1-2 MB, 4,000-6,000 lines. Rebuild with `cass-index.ps1` if >2MB.

---

### 8. OPENCODE.JSON VALID

```
try {
    Get-Content "$env:USERPROFILE\.config\opencode\opencode.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "VALID JSON"
} catch {
    Write-Host "INVALID JSON: $_"
}
```

**Expected:** Valid JSON. No hardcoded tokens.

---

### 9. GATE SYSTEM SCRIPTS

```
Test-Path "$env:USERPROFILE\.config\opencode\scripts\gate\task-init.ps1"
Test-Path "$env:USERPROFILE\.config\opencode\scripts\gate\gate-check.ps1"
Test-Path "$env:USERPROFILE\.config\opencode\scripts\gate\retro-analyze.ps1"
Test-Path "$env:USERPROFILE\.config\opencode\scripts\gate\gene-approve.ps1"
```

**Expected:** All exist.

---

### 10. T2-COMPLETE.PST1 (end-of-task logging)

```
Test-Path "$env:USERPROFILE\.config\opencode\scripts\t2-complete.ps1"
```

**Expected:** True.

---

### 11. VERIFY-DEPLOY.PS1

```
Test-Path "$env:USERPROFILE\.config\opencode\scripts\Verify-Deploy.ps1"
```

**Expected:** True.

---

### 12. HOOK SYSTEM DOCUMENTED

```
Test-Path "$env:USERPROFILE\.config\opencode\docs\hook-system.md"
```

**Expected:** True.

---

### 13. MASTER PLAN COMPLETED

```
Test-Path "$env:USERPROFILE\.config\opencode\MASTER_PLAN_AUDIT.md"
Get-Content "$env:USERPROFILE\.config\opencode\MASTER_PLAN_AUDIT.md" -Raw -ErrorAction SilentlyContinue | Select-String "ALL COMPLETE"
```

**Expected:** File exists, contains "ALL COMPLETE ✅".

---

### 14. SESSION LOG (active project tracking)

```
$logSize = [math]::Round((Get-Item "$env:USERPROFILE\.config\opencode\memory\session_log.md").Length / 1KB, 0)
Write-Host "session_log.md: ${logSize}KB"
```

**Expected:** >5KB (active session being tracked).

---

### 15. LESSONS LEARNED (continuously updated)

```
$lessonsSize = [math]::Round((Get-Item "$env:USERPROFILE\.config\opencode\memory\lessons_learned.md").Length / 1KB, 0)
Write-Host "lessons_learned.md: ${lessonsSize}KB"
```

**Expected:** >50KB (rich historical record).

---

### 16. PROJECT ACTIVE (all 7 projects documented)

```
$projActive = Get-Content "$env:USERPROFILE\.config\opencode\memory\project_active.md" -Raw
$projActive -match "PRIA|Palma Coin|Math Platform|EduFlow|BDM App|OpenCode|PC Optimizer"
```

**Expected:** All 7 projects mentioned.

---

### 17. SKILLS/DNA.YAML (behavioral genes loaded)

```
$dnaSize = [math]::Round((Get-Item "$env:USERPROFILE\.config\opencode\skills\DNA.yaml").Length / 1KB, 0)
Write-Host "DNA.yaml: ${dnaSize}KB"
Get-Content "$env:USERPROFILE\.config\opencode\skills\DNA.yaml" -First 5
```

**Expected:** >30KB, version 3.0.0.

---

### 18. AGENTS (10 specialists + manifests)

```
(Get-ChildItem "$env:USERPROFILE\.config\opencode\agents\*.md" | Measure-Object).Count
```

**Expected:** 10+ agent files.

---

### 19. RULES (20 rule files)

```
(Get-ChildItem "$env:USERPROFILE\.config\opencode\rules\*.md" | Measure-Object).Count
```

**Expected:** 18-22 files.

---

### 20. SCRIPTS (70+ utility scripts)

```
(Get-ChildItem "$env:USERPROFILE\.config\opencode\scripts\*.ps1" | Measure-Object).Count
```

**Expected:** 65-75 files.

---

## EXPECTED RESULTS — ALL GREEN

```
session_events:     ≤11K lines, ≤1MB       ✅
session-env/:       0 dirs                ✅
Token hidden:       env var, not config   ✅
swarm.py:           {"ok": true}          ✅
session.yaml:       exists               ✅
memory-bridge.js:   loaded               ✅
gate-system.js:    loaded               ✅
CASS index:        1-2MB, healthy       ✅
opencode.json:      valid JSON           ✅
Verify-Deploy.ps1:  exists              ✅
t2-complete.ps1:   exists               ✅
hook-system.md:     exists              ✅
MASTER_PLAN_AUDIT:  all ✅               ✅
```

## IF ANYTHING IS RED

Run the specific fix command from MASTER_PLAN_AUDIT.md:
```
Get-Content "$env:USERPROFILE\.config\opencode\MASTER_PLAN_AUDIT.md"
```

---

*Generated: 2026-06-03 — Master Plan Complete*