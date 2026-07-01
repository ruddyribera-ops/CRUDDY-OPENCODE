---
name: hook-system-contract
description: Contract for the 12 OpenCode plugins (memory-bridge.js, gate-system.js, post-turn-biome.js, compaction-survival.js, session-title-guard.js, pre-tool-guard.js, post-tool-guard.js, sub-agent-guard.js, checkpoint-guard.js, session-start-memory.js, main-coordinator-tracing.js, + 1 underscore). Defines failure isolation rules and fallback behavior. Each plugin MUST fail independently without cascading.
applies_to: all 12 plugins in opencode.json
triggers: any tool call, any session event
---

# Hook System Contract

## Purpose

12 plugins fire on every tool call and session event. Without isolation rules:
- One plugin's exception can block subsequent plugins
- A broken plugin silently breaks user workflow
- Hardcoded paths (DEFERRED.md L-2) cause migration friction
- Plugin chain order dependencies aren't documented

This contract defines:
1. Failure isolation rules (each plugin fails alone)
2. Event subscription scope (which plugins fire on which events)
3. Logging requirements (no silent errors)
4. Recovery behavior

---

## Plugin Inventory (12 active)

| Plugin | File | Fires on | Purpose |
|--------|------|----------|---------|
| memory-bridge.js | T1/T2/T3 lifecycle | session events |
| gate-system.js | tool.execute.before | gate enforcement |
| post-turn-biome.js | session.idle | format check |
| compaction-survival.js | session.compacting | context preservation |
| session-title-guard.js | session.idle | title validation |
| pre-tool-guard.js | tool.execute.before | dangerous op blocking |
| post-tool-guard.js | tool.execute.after | output validation |
| sub-agent-guard.js | task.dispatch | timeout detection (5-min) |
| checkpoint-guard.js | tool.execute.after | state persistence |
| session-start-memory.js | session.idle | memory flush |
| main-coordinator-tracing.js | tool.execute.before/after | observability |
| _shared.js | (helper, not standalone) | shared utilities |

---

## Failure Isolation Rules

### Rule 1: Each plugin MUST catch its own exceptions

No plugin's code path may propagate exceptions to the OpenCode event loop.

**Required pattern:**
```javascript
export const MyPlugin = async ({ event, session }) => {
  return {
    "tool.execute.before": async (ctx) => {
      try {
        // plugin logic
      } catch (e) {
        // mandatory: catch and log
        console.error(`[my-plugin] failed: ${e.message}`);
        // do NOT rethrow
      }
    }
  };
};
```

**Anti-pattern (cascading failure):**
```javascript
// BAD: throws propagate, block next plugin
"tool.execute.before": async (ctx) => {
  await doRiskyThing(ctx);  // if this throws, all subsequent plugins blocked
}
```

### Rule 2: Plugin failures MUST be logged

Every caught exception MUST log to:
- `console.error` (visible to OpenCode)
- OR `memory/hook-errors.log` (persistent)
- NOT silently swallowed

### Rule 3: Plugin order MUST NOT matter

Plugins fire in array order, but each MUST work correctly regardless of:
- Whether previous plugins succeeded or failed
- Whether subsequent plugins will run
- Plugin chain interruption (timeout, exception)

### Rule 4: Timeouts MUST NOT cascade

If a plugin times out (sub-agent-guard 5-min cap), other plugins MUST continue normally.

---

## Event Subscription Matrix

| Event | Plugin(s) that fire |
|-------|---------------------|
| session.start | session-start-memory.js |
| session.idle | session-title-guard.js, session-start-memory.js, post-turn-biome.js |
| session.compacting | compaction-survival.js |
| session.end | (memory-bridge.js if T3) |
| tool.execute.before | pre-tool-guard.js, gate-system.js, main-coordinator-tracing.js |
| tool.execute.after | post-tool-guard.js, checkpoint-guard.js, main-coordinator-tracing.js |
| task.dispatch | sub-agent-guard.js |
| T2 (task complete) | memory-bridge.js |

---

## Failure Behavior Matrix

| Plugin | Failure behavior | Recovery |
|--------|------------------|----------|
| memory-bridge.js | Log error, continue. T2 fails partially. | Re-run T2 manually |
| gate-system.js | Log error, ALLOW operation (fail-open). | Review logs, fix gate |
| post-turn-biome.js | Log warning, skip format check. | Reformat manually |
| compaction-survival.js | Log error, allow compaction (lose safety guarantees). | Manual session restart |
| session-title-guard.js | Log warning, use whatever title available. | Manual rename |
| pre-tool-guard.js | Log error, ALLOW operation (fail-open). | Review audit log |
| post-tool-guard.js | Log warning, accept output. | Manual review |
| sub-agent-guard.js | Log error, abort subagent with sentinel. | User re-dispatches |
| checkpoint-guard.js | Log error, continue without checkpoint. | Re-run checkpoint |
| session-start-memory.js | Log warning, session starts without memory flush. | Manual flush later |
| main-coordinator-tracing.js | Log warning, continue without tracing. | Tracing recovered on next event |

---

## Logging Format

All plugin errors MUST log in this format:

```
[plugin-name] event=<event-name> session=<session-id> error="<message>" stack=<stack-trace>
```

Example:
```
[pre-tool-guard] event=tool.execute.before session=PRIA-v10 error="regex timeout in BlacklistCheck" stack="..."
```

Log destinations (in priority order):
1. `console.error` — for interactive visibility
2. `memory/hook-errors.log` — for persistent record
3. NEVER `console.log` (treated as success)

---

## Hardcoded Paths Issue (DEFERRED.md L-2)

**Status:** Deferred. 11 of 12 plugins reference `C:\Users\Windows\.config\opencode\` directly.

**Migration plan when ready:**
1. Replace with `$env:USERPROFILE` or env var
2. Test with relative paths in dev
3. Roll out one plugin at a time
4. Update opencode.json after each

**Risk if migration goes wrong:** Plugin won't load, hook chain breaks for that event.

---

## Cross-references

- `opencode.json` line 211-223: plugin array
- `rules/TRIGGERS.md`: references plugin events
- `rules/agent_rules/hook-system-contract.md` (this file, in agent_rules)
- `DEFERRED.md`: L-2 hardcoded paths issue
- `t2-protocol-contract.md`: T2 step resilience

---

## Status

**APPROVED — 2026-06-29.** Adopted as part of audit fixup sprint. 12 plugins must each be audited for Rule 1 (try/catch wrapping) in next maintenance pass.