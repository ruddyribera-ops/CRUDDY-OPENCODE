---
name: t2-protocol-contract
description: Contract for scripts/t2-complete.ps1 (the 8-step end-of-task protocol). Defines mandatory fallback behavior for each step when it fails. Replaces the silent `$null` redirects and empty catch blocks that previously masked failures. Pairs with cass-index-contract.md and hook-system-contract.md.
applies_to: t2-complete.ps1, auto-memory.ps1, and any script that runs T2 steps
triggers: any time T2 protocol runs (after every task)
---

# T2 Protocol Contract

## Purpose

T2 (Task Complete) protocol runs 8 steps after every task. Without explicit fallback rules:
- A failed step silently fails (`2>$null`, empty catch)
- Output looks like success even when partial
- Audit trail is incomplete
- Recovery requires manual forensics

This contract specifies fallback behavior for each step.

---

## The 8 T2 Steps

| # | Step | Script | Purpose | Critical? |
|---|------|--------|---------|-----------|
| 1 | append-session-log.ps1 | scripts/append-session-log.ps1 | Append task to session_log.md | YES |
| 2 | update-session-yaml.ps1 | scripts/update-session-yaml.ps1 | Update session.yaml tasks[] | YES |
| 3 | track-tokens.ps1 | scripts/track-tokens.ps1 | Record token usage | NO (informational) |
| 4 | stamp-sprint.ps1 | scripts/stamp-sprint.ps1 | Stamp current_sprint.md | NO |
| 5 | auto-memory.ps1 | scripts/auto-memory.ps1 | Flush memory with real task name | YES |
| 6 | outcome-record.ps1 | scripts/outcome-record.ps1 | Append to patterns.jsonl | NO (best-effort) |
| 7 | retro-analyze.ps1 (every 10 tasks) | scripts/gate/retro-analyze.ps1 | Gene fitness scoring | NO (every 10 only) |
| 8 | graph-write-task.js | scripts/graph-write-task.js | Knowledge graph node | NO (fire-and-forget) |

---

## Step Resilience Contract

Each step MUST specify:
- **Failure behavior**: what happens when the step fails
- **Fallback**: alternative action if step fails
- **Logging**: how the failure is surfaced

### Step 1 — append-session-log (CRITICAL)

- **Failure behavior:** Step must succeed. If it fails, T2 aborts entirely.
- **Fallback:** None. Log to console + hook-errors.log; user sees "T2 step 1 failed" message.
- **Logging:** `[t2] step 1 FAILED: <error>. T2 aborted.`
- **Rationale:** session_log.md is the audit trail. If we can't log, we can't claim T2 succeeded.

### Step 2 — update-session-yaml (CRITICAL)

- **Failure behavior:** Step must succeed. session.yaml is required for FSM state.
- **Fallback:** None. If session.yaml write fails, set session state to FAILED (per session-start-contract).
- **Logging:** `[t2] step 2 FAILED: <error>. Session state set to FAILED.`

### Step 3 — track-tokens (best-effort)

- **Failure behavior:** Log warning, continue T2.
- **Fallback:** None. Token count is informational, not blocking.
- **Logging:** `[t2] step 3 warning: <error>. Token tracking skipped.`

### Step 4 — stamp-sprint (best-effort)

- **Failure behavior:** Log warning, continue T2.
- **Fallback:** None.
- **Logging:** `[t2] step 4 warning: <error>. Sprint stamp skipped.`

### Step 5 — auto-memory (CRITICAL)

- **Failure behavior:** Step must succeed. Memory flush is required for session continuity.
- **Fallback:** If auto-memory.ps1 fails, retry once. If still fails, log + continue (memory flush is best-effort on retry).
- **Logging:** `[t2] step 5 FAILED after retry: <error>. Memory flush may be incomplete.`
- **Rationale:** Without memory flush, the session loses context on resume. Better to log + warn than to fail T2 entirely.

### Step 6 — outcome-record (best-effort)

- **Failure behavior:** Log warning, continue T2.
- **Fallback:** None. patterns.jsonl is informational for evolution-agent.
- **Logging:** `[t2] step 6 warning: <error>. Pattern outcome skipped.`

### Step 7 — retro-analyze (best-effort, every 10 tasks)

- **Failure behavior:** Log warning, continue T2.
- **Fallback:** Skip gene proposal. Will retry at next 10-task threshold.
- **Logging:** `[t2] step 7 warning: <error>. Gene proposal skipped.`

### Step 8 — graph-write-task (best-effort, fire-and-forget)

- **Failure behavior:** Silent failure is acceptable IF error is logged.
- **Fallback:** None. Graph writes are advisory.
- **Logging:** Log to console if NODE_OUTPUT contains "ERROR" pattern.

---

## Aggregate Output Format

```json
{
  "task": "...",
  "agent": "...",
  "result": "Done",
  "steps_ok": ["session_log", "session_yaml", "tokens", "sprint", "auto_memory", "outcome_record", "gene_fitness", "graph_node"],
  "steps_failed": [],
  "t2_status": "COMPLETE" | "PARTIAL" | "FAILED"
}
```

**t2_status values:**
- `COMPLETE` — all 8 steps OK
- `PARTIAL` — at least 1 non-critical step failed, all critical steps OK
- `FAILED` — at least 1 critical step (1, 2, or 5) failed

Exit code:
- 0 = COMPLETE or PARTIAL (T2 attempted all steps)
- 1 = FAILED (a critical step failed; user must investigate)

---

## Anti-Patterns (FORBIDDEN)

These patterns MUST NOT appear in t2-complete.ps1:

```powershell
# BAD: silent failure
& $script 2>$null | Out-Null

# BAD: empty catch
try { ... } catch {}

# BAD: rethrow
try { ... } catch { throw }

# BAD: assume success
& $script | Out-Null
$results += "step_ok"  # marked OK but never verified
```

**Required replacements:**

```powershell
# GOOD: log on failure
& $script 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    $failed += "step: exit code $LASTEXITCODE"
    # per-step resilience rules apply
}

# GOOD: catch with logging
try {
    ...
} catch {
    $failed += "step: $($_.Exception.Message)"
    # mandatory log per step resilience rules
}

# GOOD: verify success
$result = & $script
if ($LASTEXITCODE -eq 0) {
    $results += "step_ok"
} else {
    $failed += "step: exit code $LASTEXITCODE"
}
```

---

## What this prevents

| Risk | Mitigation |
|------|------------|
| Silent step failures | Per-step logging requirements; t2_status exposed |
| Empty catch blocks swallowing errors | Anti-pattern rules + replacement patterns |
| T2 appears to succeed when partial | t2_status reflects actual outcome |
| Auto-memory loss | Step 5 has retry + warning on failure |
| Audit trail gaps | Step 1 (session_log) is critical; aborts T2 on failure |

---

## Cross-references

- `scripts/t2-complete.ps1` — the script this contract governs
- `rules/cass-index-contract.md` — sibling contract (cass-index step in T2)
- `rules/hook-system-contract.md` — sibling contract (12 plugins)
- `rules/session-start-contract.md` — sibling contract (session lifecycle)
- `rules/M3-compensation.md` — applies during handovers

---

## Status

**APPROVED — 2026-06-29.** Adopted as part of audit fixup sprint. Migration: t2-complete.ps1 already partially follows this contract (after Batch 2.3 silent catch fixes). Full migration with per-step logging verification is pending.