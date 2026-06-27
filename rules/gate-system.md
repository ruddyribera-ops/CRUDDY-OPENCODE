# Gate System — Enforced Pipeline

**Purpose:** Replace trust with proof. The gate system is code that enforces sequence, not markdown that suggests it.

**Principle:** "Agents lie. Gates verify." — Nick Nisi

---

## Core Concept

```
MARKDOWN (Knowledge):  "Test before declaring done"
GATE (Code):         "No SHA of test output = exit 1 = cannot proceed"
```

---

## Pipeline Steps

Every task flows through 4 gates:

| Step | Who | Proof Required |
|------|-----|----------------|
| implement | code-builder / specialist | file-exists, grep-null, test-output |
| verify | coordinator auto | grep-null (desired state confirmed) |
| review | code-analyzer | manual (coordinator confirms) |
| close | coordinator | summary-sha (completion logged) |

---

## Gate Scripts

| Script | Purpose |
|--------|---------|
| `task-init.ps1` | Creates state.yaml for new task |
| `gate-check.ps1` | Enforcer — exit 0=pass, exit 1=block |

### task-init.ps1

```powershell
# New task
task-init.ps1 -TaskId "2026-05-31-001" -Description "Fix login bug"

# Reset existing
task-init.ps1 -TaskId "2026-05-31-001" -Force
```

### gate-check.ps1

```powershell
# Verify proof for current step
gate-check.ps1 -TaskId "2026-05-31-001" -Step implement -ProofType file-exists -ArtifactPath "opencode.json"

gate-check.ps1 -TaskId "2026-05-31-001" -Step verify -ProofType grep-null -ArtifactPath "opencode.json" -Pattern "desktop-commander"

gate-check.ps1 -TaskId "2026-05-31-001" -Step review -ProofType manual

gate-check.ps1 -TaskId "2026-05-31-001" -Step close -ProofType summary-sha -ArtifactPath "memory/session_log.md"
```

---

## Proof Types

| Type | What it checks |
|------|----------------|
| `file-exists` | File exists at path + SHA256 recorded |
| `grep-null` | Grep returns nothing (desired clean state) |
| `grep-found` | Grep returns something (desired state found) |
| `test-output` | Test file has content + SHA recorded to artifacts/ |
| `curl-200` | URL returns HTTP 200 |
| `manual` | Coordinator manually confirms |
| `summary-sha` | Summary markdown has content + SHA |

---

## Gate Output

```
[GATE PASSED] implement - file-exists SHA: ABC123...
[GATE BLOCKED] implement - file not found: opencode.json
```

Exit code 0 = pass. Exit code 1 = block. Agent MUST fix and retry on exit 1.

---

## State File

Each task gets `gates/<task_id>/state.yaml`:

```yaml
task_id: "2026-05-31-001"
current_step: "verify"

steps:
  implement:
    status: done
    proof_sha: "ABC123..."
    gate_passed: true
    attempts: 1
    completed: "2026-05-31T09:05:00Z"
  verify:
    status: pending
    gate_passed: false
    attempts: 0
```

---

## Coordinator Integration

Before ANY routing, coordinator reads `gates/<task_id>/state.yaml`:

- If `gate_passed: false` for current step → BLOCK routing
- If gate blocked → report: "Task blocked at [step]. Evidence required."

Rule: "No bypass. No skip. Gate exit 1 = agent retries."

---

## retro-analyze.ps1

Runs every 10 tasks, reads `gates/*/state.yaml`:

```powershell
powershell -File $CONFIG/scripts/gate/retro-analyze.ps1 -TaskCount 10 -WriteGenes
```

**Exit codes:**
- `0` = analysis only (no patterns found)
- `1` = error
- `2` = genes written to DNA.yaml → trigger evolution-agent

**Behavior:**
- Identifies steps with 3+ attempts per task
- Groups by step type (implement/verify/review/close)
- Auto-writes gene candidates to `skills/DNA.yaml`
- Gene block includes: step blocked, pattern description, blocked_reason, task IDs, timestamp

**Gene format (appended to DNA.yaml):**
```yaml
  # AUTO-GENERATED GENE
  # Retro-analyze: <pattern>
  - id: CODE-AUTO-001
    name: CODE_gate_blocked_<step>
    description: |
      Gate system: step '<step>' blocked 3+ times. Pattern: <N> tasks blocked.
      Reason: <blocked_reason>. Tasks: <task_ids>.
    triggers: ["implement", "gate", "blocked", "attempts"]
    auto_generated: true
    auto_date: "<ISO timestamp>"
    auto_reason: "<blocked_reason>"
```

**Evolution-agent** reviews auto-written genes, presents to user for approval.
