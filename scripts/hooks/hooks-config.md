# HOOKS CONFIGURATION — OpenCode v3.2
# Updated: 2026-06-03 (plugin-based architecture, deprecated hooks: block)

## IMPORTANT — Architecture Change

**OpenCode uses PLUGINS only for hooks.** There is NO `hooks:` block in opencode.json like Claude Code has.
The old hooks-config.md described Claude Code's PreToolUse/PostToolUse model — that model does NOT exist in OpenCode.

**Current hook system:**
- Pre-tool enforcement → `plugins/pre-tool-guard.js`
- Post-tool enforcement → `plugins/post-tool-guard.js`
- Auto-memory (idle) → `plugins/memory-bridge.js`
- Session auto-naming → `plugins/session-title-guard.js`
- Session end → `scripts/hooks/on-stop.ps1` (still works as PowerShell script)

**To disable a plugin:** remove from `opencode.json` plugin array.

---

## Available Plugin Hooks

### Plugin Events (from opencode.ai/docs/plugins)
```
tool.execute.before    ← fires BEFORE tool runs (PreTool equivalent)
tool.execute.after     ← fires AFTER tool completes (PostTool equivalent)
shell.env              ← fires on shell startup
event: session.idle    ← fires on session idle
event: session.deleted ← fires on session close
event: session.error   ← fires on session error
event: session.created
event: session.updated
file.edited
message.part.updated
message.updated
permission.asked
permission.replied
```

### Current Plugins (registered in opencode.json)
| Plugin | Hooks | Purpose |
|--------|-------|---------|
| `memory-bridge.js` | `shell.env`, `event` | Auto-memory on idle/session-deleted, forced-idle fallback |
| `gate-system.js` | `shell.env`, `event` | Fork-bomb protection (agent depth tracking) |
| `session-title-guard.js` | `event` | Session auto-naming on first exchange |
| `pre-tool-guard.js` | `tool.execute.before` | Block destructive commands, sensitive files |
| `post-tool-guard.js` | `tool.execute.after` | Auto-lint/format on file edits |
| `post-turn-biome.js` | (post-turn) | Biome formatting after edits |
| `compaction-survival.js` | `experimental.session.compacting` | Inject memory into compaction |

---

## Legacy Hook Scripts (still work, no config needed)

| Script | Trigger | Purpose |
|--------|---------|---------|
| `scripts/hooks/on-stop.ps1` | session end | Skill proposal, sprint update, lesson trigger, log rotation |

**Note:** `pre-tool-check.ps1` and `post-tool-check.ps1` have been removed (deprecated, superseded by pre-tool-guard.js and post-tool-guard.js plugins).

---

## Adding a New Plugin

1. Create `plugins/<name>.js` with:
```javascript
export const PluginName = async () => {
  return {
    "hook.event": async (input, output) => { /* ... */ },
  }
}
```

2. Register in `opencode.json` plugin array:
```json
"plugin": [
  ...existing plugins...,
  "{env:USERPROFILE}\\.config\\opencode\\plugins\\<name>.js"
]
```

3. Restart OpenCode to load the plugin.

---

## Testing Plugin Hooks

```powershell
# Test pre-tool-guard blocks .env writes:
node -e "const g = require('./plugins/pre-tool-guard.js'); g.PreToolGuard().then(p => p['tool.execute.before']({tool:'Write',args:{path:'.env'}},{}).catch(e=>console.log('BLOCKED:',e.message)))"

# Test post-tool-guard runs on file edit:
node -e "const g = require('./plugins/post-tool-guard.js'); g.PostToolGuard().then(p => p['tool.execute.after']({tool:'Edit',args:{path:'test.js'}},{exit_code:0}))"

# Check gate-system.log for hook activity:
Get-Content memory/gate-system.log -Tail 10
```