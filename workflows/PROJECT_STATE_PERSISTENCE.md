---
name: project-state-persistence
description: Checkpoint and resume protocol for long-running project generation sessions. Persists PROJECT_STATE to disk between phases.
version: 1.0.0
type: workflow
triggers:
  - save project state
  - resume project
  - checkpoint project
  - project generation interrupted
  - continue where we left off
---

# Project State Persistence Protocol

## Problem

Long project generation sessions (7-phase → 12+ prompts) can be interrupted by:
- Context window limits
- User needing to step away
- Network drops
- Session timeouts

Without persistence, starting over from Phase 0 wastes all discovery work.

## Solution: Checkpoint + Resume

After every phase gate (G0–G4, GN), write `PROJECT_STATE` to disk. On re-run, detect the checkpoint and offer resume.

## Checkpoint File Location

```
<project-dir>/
├── .opencode/
│   ├── PROJECT_STATE.yaml      # serialized state
│   └── PROJECT_STATE.lock      # prevents concurrent writes
```

## State Schema

```yaml
meta:
  project_id: "math-platform"
  created_at: "2026-05-07T14:30:00Z"
  last_updated: "2026-05-07T15:45:00Z"
  version: "1.0.0"

discovery:
  project_type: "web_app"
  domain: "adaptive learning"
  target_users: ["students K-12", "teachers"]
  primary_problem: "personalized math practice"
  key_constraints: ["offline-first", "low bandwidth"]

architecture:
  chosen_stack:
    backend: "FastAPI"
    frontend: "Next.js 14"
    db: "PostgreSQL"
  chosen_patterns: ["async", "REST", "JWT auth"]
  deployment_model: "railway"

governance:
  contract_locked: true
  mvp_phases: [1, 2, 3]
  full_scope_phases: [1, 2, 3, 4, 5, 6, 7]
  out_of_scope: ["mobile app", "payment integration"]
  current_phase: 3
  last_gate: "G3"

history:
  approvals_log:
    - gate: "G0"
      approved_at: "2026-05-07T14:35:00Z"
      note: "user approved summary"
    - gate: "G1"
      approved_at: "2026-05-07T14:50:00Z"
      note: "stack locked: FastAPI + Next.js"
  decisions_log:
    - id: "DEC-001"
      phase: 0.5
      decision: "Choose async FastAPI over Django for real-time"
      alternatives: ["Django Channels", "Express.js"]
      reasoning: "Familiarity + PostgreSQL native async"
      user_approved: true
  open_issues: []
  deviations_flagged: []
```

## Phase Integration

### After GATE approval (automatic checkpoint)

After every gate, the `@project-generator` writes:

```python
import yaml
from pathlib import Path

def save_checkpoint(state: dict, project_dir: Path):
    """Save PROJECT_STATE after every gate approval."""
    oc_dir = project_dir / ".opencode"
    oc_dir.mkdir(exist_ok=True)

    # Atomic write: write to .tmp, then rename
    tmp = oc_dir / "PROJECT_STATE.yaml.tmp"
    lock = oc_dir / "PROJECT_STATE.lock"

    lock.write_text(str(os.getpid()))
    tmp.write_text(yaml.dump(state, default_flow_style=False))
    tmp.rename(oc_dir / "PROJECT_STATE.yaml")
    lock.unlink()
```

### On resume (detect and offer)

```python
def load_checkpoint(project_dir: Path) -> dict | None:
    """Load PROJECT_STATE if checkpoint exists."""
    state_file = project_dir / ".opencode" / "PROJECT_STATE.yaml"
    if state_file.exists():
        return yaml.safe_load(state_file.read_text())
    return None

def offer_resume(state: dict) -> bool:
    """
    Show user the checkpoint summary and ask if they want to resume.
    Returns True if resume, False if start fresh.
    """
    summary = f"""
    [RESUME CHECKPOINT FOUND]
    Project: {state['meta']['project_id']}
    Last updated: {state['meta']['last_updated']}
    Last gate: {state['governance']['last_gate']}
    Current phase: {state['governance']['current_phase']}

    Discovery: {state['discovery']['project_type']} — {state['discovery']['primary_problem']}
    Stack: {state['architecture']['chosen_stack']}

    Resume from where we left off? (yes = continue, no = start fresh)
    """
    print(summary)
    # User chooses
```

## State Locking

To prevent concurrent writes corrupting state:

```
.acquire_lock() → write → .release_lock()
```

Lock file contains PID. On write, if lock exists:
- Check if process still alive
- If dead → remove lock and write
- If alive → refuse write (another session is active)

## Recovery After Crash

If OpenCode crashes mid-phase, the checkpoint from the **last approved gate** is the recovery point:

```
Recovery targets (in priority order):
1. Last approved gate (G0, G1, G2, G3, GN)
2. Last written PROJECT_STATE.yaml
3. Start from G0 (last resort)
```

## Files Generated Per Phase

```
<project-dir>/
├── PROMPT-0-FOUNDATIONAL-CONTRACT.md   # Phase 2 output
├── PROMPT-X-CROSS-CUTTING-RULES.md     # Phase 3 output
├── PROMPT-1-PHASE-NAME.md               # Phase 4+ output (one per phase)
├── PROMPT-2-...
├── ...
├── README.md                            # Final delivery
└── REVIEW.md                            # Reviewer sign-offs
```

The checkpoint tracks which files exist and which are complete.

## Integration with code-builder

When user says "continue the project" or "resume":
1. Read `PROJECT_STATE.yaml`
2. Detect current phase from `governance.current_phase`
3. Ask user: "Resume from Phase N?"
4. Load `PROMPT-N-PHASE-NAME.md` and continue

## Lock File Protocol

```powershell
# Checkpoint before phase
$lock = ".opencode/PROJECT_STATE.lock"
$pid = [System.Diagnostics.Process]::GetCurrentProcess().Id

# Try to acquire
if (Test-Path $lock) {
    $lockPid = Get-Content $lock
    # Check if process still running
    try {
        [System.Diagnostics.Process]::GetProcessById($lockPid) | Out-Null
        Write-Host "[LOCKED] Another session is writing. Try again shortly."
        exit 1
    } catch {
        # Process dead — stale lock, remove it
        Remove-Item $lock
    }
}

# Write lock
Set-Content -Path $lock -Value $pid

# ... write state ...

# Release lock
Remove-Item $lock
```

## Integration Points

| Agent | When to checkpoint |
|-------|-------------------|
| `@project-generator` | After every GATE approval (G0–G4, GN) |
| `@code-builder` | After POA completion audit |
| `@bug-fixer` | After fix verification |

## Anti-Patterns

- ❌ Checkpoint on every tool call (too noisy)
- ❌ Checkpoint mid-phase (state is incomplete)
- ❌ Store state in memory only (lost on crash)
- ✅ Checkpoint after gate approval only
- ✅ Store state in versioned file (survives crash)
- ✅ Atomic rename for write safety
