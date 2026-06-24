# Dispatch Stalling Prevention (M0.5 Incident)

**Date:** 2026-06-22
**Reporter:** Account Manager (PRIA v10 session)
**Severity:** HIGH — 8-hour session that should have been 2 hours
**Affected scope:** ALL projects using sub-agent dispatch (system-level)

---

## What happened

During the PRIA v10 M0.5 fix sprint:
- 5+ sub-agent dispatches returned "Task cancelled" silently — no error, no partial output, no exit code
- Server lifecycle commands (Stop-Process + Start-Process) hung for 2-10 minutes without progress feedback
- TypeScript build did not copy .md prompt files from src/ to dist/ — caused a 5-minute debug on source-narrator
- The `t2-complete.ps1` audit script was broken (PS5.1 parser errors from a duplicate hash literal), so session logs were silently failing
- The AM and coordinator retry protocols existed in their agent rules but neither was using them — the rules were buried under narrative and not enforced

Total time wasted: ~2.5 hours out of an 8-hour session.

---

## Root causes (3 layers)

### Layer 1: Sub-agent delegation
- Sub-agent dispatches have NO native timeout or abort in OpenCode's plugin API
- Prompts >1500 chars have a high failure rate (sub-agent-guard plugin returns empty)
- No retry protocol was actively used even though it was documented

### Layer 2: Server lifecycle
- PowerShell process management is silent — Stop-Process + Start-Process can hang for 2-10 min
- tsc does not copy non-TS files (`.md`, `.json`) — leads to silent drift between src/ and dist/
- Prompt cache in-memory Maps don't invalidate on file change — edits have no effect until server restart

### Layer 3: Logging & enforcement
- `t2-complete.ps1` had a duplicate `$taskTypeMap = @{$taskTypeMap = @{` causing PS5.1 to misinterpret the file as nested hash syntax
- Without T2 working, dispatch outcomes were not auditable
- The patterns existed in rules but were not enforced (no checklist, no auto-trigger)

---

## System-level fixes applied

### 1. Coordinator layer (main-coordinator.md)
- Added COORDINATOR DISPATCH RETRY PROTOCOL — explicit flow on `[SUB-AGENT-GUARD]` sentinel
- Added COORDINATOR DISPATCH AUDIT LOG spec — JSONL format per dispatch
- Added COORDINATOR WATCHDOG WRAPPER — `dispatchWithWatchdog()` pattern with timeout + abort
- Added post-mortem reference in Session Start — coordinator reads this file on session start

### 2. AM layer (account-manager.md)
- Added DISPATCH AUDIT LOG section (JSONL format)
- Added WATCHDOG WRAPPER with `dispatchWithWatchdog()` code example
- Added prominent RETRY PROTOCOL callout (the rule was already there but buried; now NON-OPTIONAL)
- Added TRIVIAL DISPATCH THRESHOLD rule (minimal ceremony for <50 line changes, but never bypass role)

### 3. Infrastructure
- Fixed `scripts/t2-complete.ps1` — removed duplicate hash literal opening (line 106)
- Verified `plugins/sub-agent-guard.js` — already provides timeout detection (5 min default) and exports `simplifyPrompt()` helper; cannot abort (OpenCode plugin API limitation) so dispatcher owns the retry loop

### 4. PRIA project (project-specific, not system-level)
- Created `scripts/restart-server.ps1` with health check loop and DryRun flag
- Modified `server/src/routes/motores.ts` — prompt cache now invalidates on file mtime change (no restart needed)
- Modified `server/package.json` build script — adds `xcopy` for prompt `.md` files (since TS `copyFiles` compiler option does not exist in TS 5.9.3)

---

## Hard rules (apply to ALL projects)

1. **Every `task()` dispatch goes through `dispatchWithWatchdog()`** — never call `task()` directly. No exceptions.
2. **On `[SUB-AGENT-GUARD]` sentinel, ALWAYS retry ONCE with `simplifyPrompt()`** — strip code blocks, truncate to <300 chars. Never retry with the same prompt.
3. **Prompts >1500 chars MUST be simplified BEFORE first dispatch**, not after failure. The first attempt should be small.
4. **T2 logging is mandatory after every task** — `scripts/t2-complete.ps1` is the heartbeat. If it fails, fix it before continuing (do NOT skip logging).
5. **Server lifecycle ops need explicit progress feedback** — wrap Stop-Process + Start-Process in a health check loop. Never assume silent success.
6. **Prompt caches must invalidate on file change** — store mtime with cached content, compare before returning cached value.

---

## Detection patterns (run these on every session start)

```bash
# 1. Audit log analysis (last 30 days)
test -f memory/factory/audit.jsonl && \
  grep -c '"outcome":"timeout"' memory/factory/audit.jsonl || echo "audit.jsonl missing"

# 2. T2 script health
powershell -NoProfile -File scripts/t2-complete.ps1 -TaskName "health-check" -Agent "main-coordinator" -Result "Done" -Tokens 0
# Expected: exit 0, prints "T2 complete: health-check"
# If parser error: fix the script IMMEDIATELY

# 3. Post-mortem freshness
ls -lt rules/agent_rules/*.md | head -5
# Newest should be within 30 days; if all older, the system is not learning
```

---

## Cross-references

- `agents/main-coordinator.md` — COORDINATOR DISPATCH RETRY PROTOCOL, AUDIT LOG, WATCHDOG WRAPPER
- `agents/account-manager.md` — DISPATCH AUDIT LOG, WATCHDOG WRAPPER, RETRY PROTOCOL, TRIVIAL THRESHOLD
- `plugins/sub-agent-guard.js` — timeout detection, `simplifyPrompt()` helper export
- `scripts/t2-complete.ps1` — end-of-task logging (now fixed)
- `D:\ACTIVE PROJECTS\PRIA v10\docs\factory-ops-stalling-report.md` — original incident report from AM
