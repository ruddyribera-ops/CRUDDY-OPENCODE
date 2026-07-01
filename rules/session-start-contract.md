---
name: session-start-contract
description: Contract for session lifecycle FSM (Finite State Machine). Defines valid states for sessions, transition rules, and failure recovery. Both main-coordinator (initiator) and session_machine.ps1 (enforcer) reference this contract. Prevents the silent failure where session state is ambiguous or stuck.
applies_to: main-coordinator, session_machine.ps1, memory-bridge.js plugin
triggers: any time a session starts, resumes, or transitions between states
---

# Session Start Contract — FSM Lifecycle

## Purpose

Sessions can enter ambiguous states when:
- Session start fails partway through (checkpoint load OK, session.yaml write fails)
- Resume logic can't determine state (corrupt session.yaml)
- Multiple parallel startups race (two session.idle events)
- Required files missing (handover/latest.md, project_active.md)

Without a contract, the system silently proceeds with partial state, leading to:
- Lost work (T2 never fired for half-done tasks)
- Duplicate tasks (T1 fired twice)
- Confusing session names ("Untitled" instead of project-intent)

This contract defines the FSM with explicit transitions, validations, and recovery rules.

---

## State Machine

```
                    ┌──────────────┐
                    │   ABSENT     │ (no session.yaml exists)
                    └──────┬───────┘
                           │ session.idle event
                           ▼
                    ┌──────────────┐
                    │   PENDING    │ (session.idle detected, init started)
                    └──────┬───────┘
                           │ T1 begins
                           ▼
                    ┌──────────────┐
                    │  STARTING    │ (loading checkpoint, handover, project_active)
                    └──────┬───────┘
                           │ T1 complete (or skipped)
                           ▼
              ┌────────┬──────────────┐
              │        │              │
   T1 failed  │        │  T1 OK       │ (resume decision made)
              ▼        │              ▼
       ┌─────────┐     │       ┌──────────────┐
       │ FAILED  │     │       │    ACTIVE    │ (accepting tasks)
       └────┬────┘     │       └──────┬───────┘
            │          │              │
            │ manual   │              │ session.idle auto
            │ recovery │              ▼
            │          │       ┌──────────────┐
            │          │       │    IDLE      │ (waiting for prompt)
            │          │       └──────┬───────┘
            │          │              │ user prompt
            │          │              ▼
            │          │       back to ACTIVE
            │          │
            │          └─────────►  (any state can transition to FAILED on uncaught exception)
            ▼
       ┌──────────┐
       │  ENDED   │ (session.end event)
       └──────────┘
```

---

## States

| State | Meaning | Persisted in session.yaml? |
|-------|---------|---------------------------|
| `ABSENT` | No session.yaml exists; system has never started a session here | n/a |
| `PENDING` | session.idle event fired; main-coordinator detected it; init in progress | NO (transient) |
| `STARTING` | T1 protocol executing (load checkpoint, handover, project_active, auto-summary) | NO (transient) |
| `ACTIVE` | T1 complete; session accepting tasks | YES |
| `IDLE` | No active task; waiting for user prompt | YES |
| `FAILED` | T1 or session operation failed; manual recovery needed | YES |
| `ENDED` | session.end event fired; session.yaml finalized | YES (terminal) |

---

## Valid Transitions

| From | To | Trigger | Pre-conditions |
|------|------|---------|----------------|
| ABSENT | PENDING | session.idle | none |
| PENDING | STARTING | T1 begins | handover file exists OR fresh-start chosen |
| STARTING | ACTIVE | T1 complete | session.yaml created, project_active loaded |
| STARTING | FAILED | T1 error | critical step failed (session.yaml, knowledge graph) |
| STARTING | ACTIVE | user: "fresh start" | skip handover |
| ACTIVE | IDLE | session.idle auto-event | no active task |
| IDLE | ACTIVE | user prompt | prompt received |
| ACTIVE | FAILED | uncaught exception | any state can fail |
| ACTIVE | ENDED | session.end | user ends session |
| IDLE | ENDED | session.end | user ends session |
| FAILED | ACTIVE | user: "recover" | manual recovery confirmed |

**Invalid transitions** (must NOT occur):
- ABSENT → ACTIVE (must go through STARTING)
- PENDING → ENDED (must complete T1 or fail)
- ACTIVE → ABSENT (session.yaml is always persisted)
- Any → STARTING (STARTING is one-shot per session)

---

## T1 Steps (the STARTING transition)

Each step has:
- Pre-condition: must be true before step runs
- Action: what the step does
- Post-condition: must be true after step succeeds
- Fallback: what to do if step fails

### Step 1: Load checkpoint

- Pre: `memory/checkpoint.yaml` may exist
- Action: read checkpoint, set resume pointer
- Post: `state.resume_step` set in session.yaml
- Fallback: if checkpoint missing, set `state.resume_step: 0` (fresh start)

### Step 2: Load handover

- Pre: `handover/latest.md` may exist
- Action: parse handover context, pending items
- Post: `handover.loaded` set in session.yaml
- Fallback: if missing, set `handover.loaded: false`, continue

### Step 3: Load project_active

- Pre: `project_active.md` may exist
- Action: load current project state
- Post: `projects_touched[]` populated
- Fallback: if missing, log warning, continue with empty projects

### Step 4: Auto-summarize (graph)

- Pre: graph exists
- Action: run `auto-summary.js --project <current> --days 30`
- Post: `auto_summary` field populated in session.yaml
- Fallback: fire-and-forget; skip on error (never block session start)

### Step 5: Create session entity

- Pre: graph write available
- Action: create session node, wire relations
- Post: graph node exists with metadata
- Fallback: log warning if graph write fails; continue

### Step 6: Create/update session.yaml

- Pre: session.yaml path known
- Action: write session.yaml with status=ACTIVE
- Post: session.yaml exists, status=ACTIVE
- Fallback: if write fails, set status=FAILED, abort T1

### Step 7: Present to user

- Pre: session.yaml active, projects loaded
- Action: output 2-3 line summary (name, context, state)
- Post: user has context
- Fallback: cannot fail (output is local)

---

## Recovery Rules

### FAILED state recovery

When a session enters FAILED state:

1. Surface the failure reason to the user
2. Do NOT silently retry (could loop)
3. Offer explicit recovery options:
   - "Retry from checkpoint" — reload state from last good checkpoint
   - "Fresh start" — discard session.yaml, start new
   - "Continue manually" — proceed without session tracking
4. Update session.yaml status only after user chooses

### Stale session.yaml recovery

If session.yaml exists but is older than 7 days:

1. Warn the user
2. Ask: archive, discard, or continue?
3. Never auto-archive or auto-discard

---

## Failure Logging

Every transition (including failures) MUST be logged:

```json
{
  "ts": "2026-06-29T22:00:00Z",
  "session_name": "...",
  "from_state": "PENDING",
  "to_state": "STARTING",
  "trigger": "T1 begins",
  "result": "OK"
}
```

Failed transitions:

```json
{
  "ts": "2026-06-29T22:00:00Z",
  "session_name": "...",
  "from_state": "STARTING",
  "to_state": "FAILED",
  "trigger": "T1 step 6 (session.yaml write)",
  "result": "FAIL",
  "error": "Access denied to memory/session.yaml"
}
```

Log destination: `memory/session_events.jsonl` (append-only).

---

## What this prevents

| Risk | Mitigation |
|------|------------|
| Session starts half-done (some state loaded, some not) | T1 must complete all steps or transition to FAILED |
| Resume decision ambiguous | Explicit state field in session.yaml |
| Session name "Untitled" | Step 7 explicit output, OpenCode uses it for auto-naming |
| Two session.idle events race | State machine serializes; second event sees ACTIVE/IDLE, skips T1 |
| Corrupt session.yaml | Detection in T1 step 6; transition to FAILED, prompt recovery |

---

## Cross-references

- `plugins/memory-bridge.js` — fires session.idle events
- `scripts/session_machine.ps1` — implements T1 steps
- `agents/main-coordinator.md` — orchestrates T1
- `rules/TRIGGERS.md` — references this contract (now UTF-8 clean)

---

## Status

**APPROVED — 2026-06-29.** Adopted as part of audit fixup sprint. Replaces ad-hoc TRIGGERS.md with formal state machine.