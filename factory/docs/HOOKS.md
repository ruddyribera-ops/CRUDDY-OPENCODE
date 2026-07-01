# OpenCode Hooks System

## Config File Location

**The actual OpenCode config that is read:**
```
~/.config/opencode/opencode.json
```

> Note: `~/.config/opencode/scripts/hooks/hook-config.json` is NOT read by OpenCode. It was a prior attempt that wrote to the wrong path. The real config is `opencode.json` at the config root.

## How Hooks Work

OpenCode reads `opencode.json` for its configuration. Hooks are defined in a `hooks` section at the root level. Each hook specifies:

- `enabled`: boolean
- `script`: absolute path to the script to execute
- `description`: human-readable description

## Hook Events Supported

Based on `opencode.json`, the following hook events are configured:

| Event | Handler | Script Path | Purpose |
|-------|---------|-------------|---------|
| `sessionStart.memoryRetrieval` | SessionStart | `~/.config/opencode/factory/hooks/session_start.py` | Injects relevant memories at session start |

## Adding a New Hook

1. Edit `~/.config/opencode/opencode.json`
2. Add a new key under `hooks` (e.g., `onStop`, `postEdit`, `postToolCall`)
3. Specify `enabled`, `script` (absolute path), and `description`
4. Restart OpenCode or start a new session

Example:
```json
"hooks": {
    "sessionStart": {
        "memoryRetrieval": {
            "enabled": true,
            "script": "{env:USERPROFILE}\\.config\\opencode\\factory\\hooks\\session_start.py",
            "description": "Injects relevant memories at session start"
        }
    }
}
```

## SessionStart Hook Details

The `session_start.py` script:
1. Imports `memory_retrieval.hook_integration.on_session_start()`
2. Prints the returned `context_block` to stdout (UTF-8 encoded)
3. Always exits 0 — failures are logged to stderr but don't crash the session
4. If no memories are found, outputs `<!-- memory-retrieval: no memories available -->`

## Testing Hooks

```powershell
# Test the session_start hook in isolation
python ~/.config/opencode/factory/hooks/session_start.py 2>$null
```

## Files

| File | Purpose |
|------|---------|
| `opencode.json` | Main OpenCode config — ADD hooks here |
| `factory/hooks/session_start.py` | SessionStart handler script |
| `scripts/hooks/hook-config.json` | **DEPRECATED** — wrong path, not read |
| `factory/scripts/memory_retrieval/hook_integration.py` | Contains `on_session_start()` function |
