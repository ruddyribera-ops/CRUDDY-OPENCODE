# Master Plan Update: DIY Swarm Research Findings
**Date:** 2026-06-02
**Appended to:** master-plan-2026-06-01.md

---

## Feature 4 — opencode-swarm (DEEP RESEARCH UPDATED)

### What Swarm Actually Does (from swarmtools.ai + joelhooks/swarm-tools GitHub)

**Core architecture (687 stars, 59 forks, 973 commits):**
```
Task → Coordinator → Decompose → Spawn Workers (parallel)
                              ↓
                         Checkpoints (at 25%, 50%, 75%)
                              ↓
                         Swarm Mail (durable messaging)
                              ↓
                         Outcome Log (learn from success/fail)
```

### Key Components + DIY Approach

| Component | What it does | DIY solution |
|-----------|-------------|--------------|
| **Checkpoint system** | Saves at 25/50/75% to libSQL | JSON files in `memory/checkpoints/` |
| **Swarm Mail** | DurableMailbox, DurableLock | Extend `scripts/mail.py` with reserve/release |
| **Outcome learning** | fast+success→promote, slow+errors→demote | `patterns.jsonl` + scoring formula |
| **Beads (Hive)** | Git-backed task tracking | JSON in `memory/hive/` + git commit per bead |
| **CASS** | Session search (849 stars, Rust binary) | Skip for now — no Windows binary |
| **Compaction hook** | `experimental.session.compacting` | Critical — inject checkpoint into session |

### Critical Compatibility Finding

- **swarm-tools is TypeScript** (86% TS) — designed for Node.js Bun plugin system
- **OpenCode Go** uses `.js` plugins from `plugin:` array in opencode.json
- **npm install keeps timing out** — package too large for your connection
- **Verdict:** Plugin incompatible with OpenCode Go. DIY is the path.

### What You Already Have (Swarm Precursors)

| Swarm feature | Your existing | Status |
|---------------|--------------|--------|
| Parallel dispatch | `main-coordinator.md` parallel batch | ✅ Done |
| Agent mail | `scripts/mail.py` | ✅ Done |
| Resource locking | `main-coordinator.md` | ✅ Done |
| Checkpoint/recovery | None | ❌ Build |
| Outcome learning | None | ❌ Build |
| File reservations | Basic | ⚠️ Enhance |
| Beads/Hive | None | ❌ Build |

---

## DIY Swarm — Core Components

### 1. Checkpoint System

**Checkpoint storage:**
```
memory/checkpoints/
  ├── session_<id>_latest.json   (current state)
  └── checkpoint_index.jsonl    (append-only log)
```

**Schema:**
```json
{
  "session_id": "abc123",
  "created_at": "2026-06-01T12:00:00Z",
  "progress_percent": 50,
  "files_modified": ["src/auth.ts"],
  "strategy": "file-based",
  "agent_count": 3,
  "pending_tasks": ["worker-c: tests"],
  "coordinator_directives": "Use bcrypt",
  "next_action": "spawn worker-c"
}
```

**Recovery:** Load latest checkpoint, inject via `experimental.session.compacting` hook.

### 2. Outcome Learning

**Pattern scoring:**
```
score = (success_rate × 0.7) + (speed_factor × 0.3)
speed_factor = median_duration / this_duration (cap 2.0)

>1.2 = proven
<0.5 = anti-pattern
>60% failure rate = auto-flag as anti-pattern
```

**Storage:**
```
memory/outcomes/
  ├── patterns.jsonl       (append-only log)
  └── pattern_maturity.yaml (computed scores)
```

### 3. Swarm Mail Enhancement

**Add to mail.py:**
```powershell
mail.py reserve <agent> --paths "src/auth/*" --exclusive true
mail.py release <agent> --paths "src/auth/*"
```

**SQLite tracking:**
```sql
CREATE TABLE file_reservations (
  id TEXT PRIMARY KEY,
  agent TEXT NOT NULL,
  paths TEXT NOT NULL,  -- JSON array
  exclusive INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  released_at TEXT
);
```

### 4. Beads (Hive)

**Storage:**
```
memory/hive/
  ├── beads_index.jsonl    (all beads ever)
  └── active/
      ├── bd-001.json
      └── bd-002.json
```

**Schema:**
```json
{
  "id": "bd-001",
  "title": "Implement auth service",
  "type": "feature",
  "status": "in_progress",
  "agent": "worker-a",
  "files_reserved": ["src/auth/*"],
  "created_at": "2026-06-01T12:00:00Z",
  "completed_at": null,
  "outcome": null
}
```

### 5. CASS Decision

- **CASS:** 849 stars, Rust binary, no Windows release
- **pip install** would need Rust toolchain — fails on Windows without Rust
- **Skip.** Your mail.py + outcome log already capture the key data.

### 6. Compaction Survival Hook (CRITICAL)

**The `experimental.session.compacting` hook:**
- Fires before LLM generates continuation summary (context about to be compacted)
- Plugin can inject context OR replace the entire prompt
- This is how checkpoints get restored into the session

```javascript
"experimental.session.compacting": async (input, output) => {
  const checkpoint = load_latest_checkpoint();
  const patterns = load_patterns();
  
  output.context.push(`
## Session Recovery
Last checkpoint: ${checkpoint.progress_percent}% complete
Files in flight: ${checkpoint.files_modified.join(', ')}
Pending: ${checkpoint.pending_tasks.join('; ')}

## Learned Patterns
${patterns.map(p => `- ${p.task_type}: ${p.maturity}`).join('\n')}
`);
}
```

---

## Implementation Phases

```
PHASE 1 — Biome Post-Turn Hook
  1.1 Create plugins/post-turn-biome.js
  1.2 Add to opencode.json plugin array
  1.3 Test on sample project
  → Time: ~2 hours

PHASE 2 — Checkpoint System
  2.1 checkpoint-save.ps1 + checkpoint-load.ps1
  2.2 checkpoint-recover.ps1 (compaction injection)
  2.3 Update gate-system.js to save at 25/50/75%
  → Time: ~4 hours

PHASE 3 — Outcome Learning
  3.1 patterns.jsonl schema
  3.2 outcome-score.ps1 (scoring logic)
  3.3 Pattern injection into coordinator prompt
  → Time: ~4 hours

PHASE 4 — Swarm Mail Enhancement
  4.1 Add reserve/release to mail.py
  4.2 File reservation SQLite tracking
  → Time: ~3 hours

PHASE 5 — Beads/Hive
  5.1 beads.ps1 CRUD
  5.2 Git commit per bead
  → Time: ~4 hours

PHASE 6 — Compaction Survival Hook (CRITICAL)
  6.1 compaction-survival.js
  6.2 Inject checkpoint + patterns into compaction
  → Time: ~2 hours

PHASE 7 — Fork Bomb Protection (LOW PRIORITY)
  7.1 Agent depth tracking in gate-system.js
  → Time: ~4 hours (may skip)

Total: ~23 hours
```

---

## Architecture Diagram

```
SESSION START
     │
     ▼
┌────────────────────────┐
│ CHECKPOINT CHECK       │
│ memory/checkpoints/    │
│    ├── no checkpoint → fresh session
│    └── has checkpoint → load → inject via
│                         experimental.session.compacting
└────────────┬───────────┘
             │
             ▼
┌────────────────────────┐
│ COORDINATOR            │
│ Before decompose:      │
│   → Load patterns.jsonl│
│   → Inject learned     │
│     patterns into prompt│
│ After worker completes: │
│   → Record outcome     │
│   → Compute score      │
└────────────┬───────────┘
             │
    ┌────────┼────────┐
    ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐
│Worker│ │Worker│ │Worker│
│🔒    │ │🔒    │ │🔒    │
└──┬───┘ └──┬───┘ └──┬───┘
   │        │        │
   └────────┼────────┘
            ▼
┌────────────────────────┐
│ SWARM MAIL             │
│ scripts/mail.py        │
│ + reserve/release      │
└────────────┬───────────┘
             │
             ▼
┌────────────────────────┐
│ CHECKPOINT (25/50/75%) │
│ checkpoint-save.ps1    │
└────────────┬───────────┘
             │
             ▼
┌────────────────────────┐
│ OUTCOME LEARNING       │
│ outcome-score.ps1       │
│ → patterns promote/    │
│   demote               │
└────────────────────────┘
```

---

## Files to Create

```
~/.config/opencode/
├── biome.json                              ✅
├── memory/
│   ├── plans/
│   │   └── master-plan-2026-06-01.md       ✅
│   ├── checkpoints/                        🆕
│   │   ├── session_<id>_latest.json
│   │   └── checkpoint_index.jsonl
│   ├── outcomes/                            🆕
│   │   ├── patterns.jsonl
│   │   └── pattern_maturity.yaml
│   ├── hive/                                🆕
│   │   ├── beads_index.jsonl
│   │   └── active/
│   └── mailboxes/                           ✅
├── scripts/
│   ├── checkpoint-save.ps1                  🆕
│   ├── checkpoint-load.ps1                  🆕
│   ├── checkpoint-recover.ps1               🆕
│   ├── outcome-score.ps1                    🆕
│   ├── beads.ps1                            🆕
│   └── mail.py                              ✅
└── plugins/
    ├── gate-system.js                      ✅
    ├── memory-bridge.js                    ✅
    ├── compaction-survival.js              🆕
    └── outcome-logger.js                    🆕
```

---

## Next Action

**Start with Phase 1 — Biome Post-Turn Hook.**
Quickest win. Validates JS plugin approach works. Tests that `tool.execute.after` hook fires and we can run `biome check --write` on modified files.

Want me to proceed?