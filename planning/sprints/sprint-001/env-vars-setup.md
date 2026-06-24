# Setting Up Environment Variables for OpenCode

OpenCode reads API keys from Windows environment variables instead of the config file. This is more secure (keys aren't in plain text) and lets you rotate keys without editing config.

> **Last updated:** 2026-06-24 — Sprint 003 trimmed providers. Only 4 env vars are required now (was 9 before).

## Required variables (current)

| Variable | Used by | Status |
|----------|---------|--------|
| `MINIMAX_API_KEY` | Primary LLM provider | **SET** (125 chars, MiniMax Coding Plan key) |
| `OPENCODE_API_KEY` | OpenCode Go provider | **SET** (67 chars) |
| `GROQ_API_KEY` | Groq models (llama-3.3-70b, qwen, etc.) | **SET** (56 chars) |
| `PLAYWRIGHT_MCP_TOKEN` | Playwright MCP auth | **SET** (43 chars) |

All 4 required env vars are currently set. No missing keys.

## Removed in Sprint 003

The following providers/MCPs were removed because they were configured but never used (caused silent 401 errors):

| Removed | Reason |
|---------|--------|
| Provider `openrouter` (12 free models) | `OPENROUTER_API_KEY` unset → silent failures |
| Provider `cerebras` (gpt-oss-120b, zai-glm-4.7) | `CEREBRAS_API_KEY` unset → silent failures |
| MCP `auto-browser` | 3 unset env vars (`AUTO_BROWSER_TOKEN`, `OPERATOR_ID`, `OPERATOR_NAME`); disabled anyway |

If you ever want these back, re-add the provider block to `opencode.json` and set the env var.

## How to set on Windows 11 (PowerShell, persistent)

```powershell
# Set user-level env var (survives reboots)
[Environment]::SetEnvironmentVariable("GROQ_API_KEY", "your-key-here", "User")

# Verify
[Environment]::GetEnvironmentVariable("GROQ_API_KEY", "User")
```

Or via System Properties:
1. Win+R → `sysdm.cpl` → Advanced tab → Environment Variables
2. New (under User variables) → Variable name = `GROQ_API_KEY`, Value = your key
3. Repeat for each var above
4. Restart any open terminals/PowerShell sessions

## Verify OpenCode picks them up

After setting and restarting OpenCode, run any command that uses the provider. If the key resolves to empty, you'll see auth errors. To check what OpenCode sees:

```powershell
# In a new PowerShell session:
echo $env:GROQ_API_KEY     # Should print your key (not empty)
```

## What happens if an env var is missing

OpenCode docs state: *"If the environment variable is not set, it will be replaced with an empty string."* This means API calls silently fail with auth errors — not a startup crash.

Symptom: model calls fail with 401/403 errors. Fix: set the env var, restart OpenCode.

**Sprint 003 mitigation:** Removed providers/MCPs that referenced unset vars. If you see 401/403 errors after this change, the cause is now limited to the 4 vars in the table above.