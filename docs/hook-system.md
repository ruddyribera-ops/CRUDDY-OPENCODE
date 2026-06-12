# OpenCode Hook System — Architecture Documentation

**Date:** 2026-06-03
**Purpose:** Clarify OpenCode's two-hook-mechanism (not one), explain what exists vs what was misread.

---

## The Confusion

TRIGGERS.md references `hook-startup.ps1` which sounds like a Claude Code hook event.
The `hooks/hooks` file was expected to exist but never did.

**Root cause:** "Hook" in TRIGGERS.md means "PowerShell protocol script called by coordinator."
Not a Claude Code hook (which uses `.claude/hooks/` JSON config).

---

## OpenCode Has TWO Hook Mechanisms

### 1. JS Plugins (Primary — Currently Working)

**Location:** `plugins/*.js`

**What:** Handle session lifecycle events, memory, gate enforcement, tool guards.

**Loaded in:** `opencode.json` → `plugin: [...]`

| Plugin | Purpose |
|--------|---------|
| `memory-bridge.js` | auto-memory, graph writes, retro-analyze, session_events rotation |
| `gate-system.js` | agent depth tracking, fork-bomb protection |
| `session-title-guard.js` | session naming from context |
| `pre-tool-guard.js` | permission checks before tool execution |
| `post-tool-guard.js` | post-execution checks |
| `post-turn-biome.js` | biome lint after turns |
| `compaction-survival.js` | context compaction memory |

**Hook events they respond to:**
- `session.idle` → triggers auto-memory flush
- `session.deleted` → final flush + session_events rotation
- `session.error` → error logging
- `shell.env` → injects config paths
- `experimental.session.compacting` → memory injection into context

**NOT Claude Code hooks** — these are OpenCode plugin event handlers.

---

### 2. PowerShell Protocol Scripts (Called by Coordinator)

**Location:** `scripts/*.ps1`

**What:** Called by coordinator via TRIGGERS.md protocol. These are workflow scripts, not event hooks.

**Examples:**
| Script | Called by | Purpose |
|--------|----------|---------|
| `auto-memory.ps1` | memory-bridge.js (JS plugin) | Flush task to session_log.md |
| `t2-complete.ps1` | main-coordinator.md (T2) | End-of-task logging |
| `stamp-sprint.ps1` | main-coordinator.md (T2) | Sprint tracking |
| `track-tokens.ps1` | main-coordinator.md (T2) | Token budget |
| `archive-handovers.ps1` | main-coordinator.md (T3) | Handover rotation |
| `hook-wrapper.ps1` | main-coordinator.md (T9) | Destructive command guard |
| `save-checkpoint.ps1` | main-coordinator.md (Checkpoint) | State persistence |
| `write-handover.ps1` | main-coordinator.md (T3) | Generate handover/latest.md |

**How they work:** The coordinator CALLS these scripts at specific protocol points (T1-T9).
They're not auto-fired by OpenCode events.

---

## What NOT to Build

### ❌ `.claude/hooks/` directory (Claude Code hook system)
OpenCode is NOT Claude Code. It uses JS plugins, not shell command hooks.
- Claude Code hooks: `.claude/hooks/<hook-name>.sh` + `.claude/settings.json` → fires on lifecycle events
- OpenCode: `plugins/*.js` → fires on session events

### ❌ `hooks/hooks` file
This was a misread of TRIGGERS.md. The reference to `hook-startup.ps1` is to a PowerShell
protocol script, not a hook per se.

---

## How to Add a New Plugin Hook

1. Create `plugins/my-plugin.js`:
```javascript
export const MyPlugin = async () => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        // do something
      }
    },
    "shell.env": async (_input, output) => {
      output.env.MY_VAR = "value"
    }
  }
}
```

2. Add to `opencode.json`:
```json
"plugin": [
  "...existing...",
  "C:\\Users\\Windows\\.config\\opencode\\plugins\\my-plugin.js"
]
```

3. Restart OpenCode to load.

---

## How to Add a Protocol Script

1. Create `scripts/my-script.ps1`
2. Call it from the coordinator at the appropriate T trigger point
3. Document in TRIGGERS.md which T trigger calls it

Example — T2 calls `t2-complete.ps1`:
```powershell
powershell scripts/t2-complete.ps1 -TaskName "<name>" -Agent "<agent>" -Result "Done" -Tokens <N>
```

---

## Summary

| Question | Answer |
|---|---|
| Does OpenCode have hooks? | Yes — JS plugins responding to session events |
| Does it use Claude Code's hook system? | No |
| Is `hooks/hooks` missing? | Irrelevant — it was never the right architecture |
| What does TRIGGERS.md T1 mean by `hook-startup.ps1`? | A PowerShell script called on session start (via protocol, not event) |
| Can I add a new hook? | Yes — create a JS plugin and add to opencode.json |

---

*Generated post audit — clarifies two-mechanism architecture.*