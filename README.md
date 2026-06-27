# CRUDDY-OPENCODE

Production-ready OpenCode configuration with audit hardening, defensive plugins, and portable paths.

## What This Is

A battle-tested OpenCode setup with:

- **25 specialized agents** (main-coordinator, code-builder, code-reviewer, expert-tester, ai-evaluator, observability-sre, designer, etc.)
- **110+ PowerShell scripts** (track-tokens, validate-config, checkpoint-save, health-checks)
- **15 JS plugins** (memory-bridge, gate-system, sub-agent-guard, checkpoint-guard, compaction-survival, etc.)
- **31 skill packs** (adversarial testing, superpowers, awesome-office-hours, ios/android dev, etc.)
- **24 rule files** (challenger rule, M3 compensation, batch-file modification safety, etc.)
- **8 factory docs + 9 planning specs** for memory retrieval and autoresearch systems

## Origin Story

This config was assembled over many sessions of daily use, then hardened via a comprehensive two-lens audit (structural + adversarial) that found **30 unique issues**. Of those:

- **2 CRITICAL** (runtime failures) — fixed
- **7 HIGH** (config rot, broken refs, bloated prompts) — fixed
- **11 MEDIUM** (defensive code gaps, doc inaccuracies) — fixed
- **8 LOW** (cosmetic, tuning) — addressed or deferred with rationale
- **1 deferred** (path portability across machines) — rationale in `DEFERRED.md`

After fixes: `validate-config.ps1` reports **0 FAILs** across 87 checks.

## Installation

### Prerequisites

- **OpenCode** installed and working
- **PowerShell 5.1+** (default on Windows; install via `winget install Microsoft.PowerShell` on Linux/macOS)
- **Node.js 18+** (for JS plugins)
- **Python 3.10+** (optional, for `factory/scripts/` Python tooling)

### Setup

```powershell
# Clone this repo
git clone https://github.com/ruddyribera-ops/CRUDDY-OPENCODE.git

# Option A: Symlink as your OpenCode config
# (Linux/macOS)
ln -s "$(pwd)/CRUDDY-OPENCODE" ~/.config/opencode

# (Windows PowerShell — run as Administrator)
New-Item -ItemType Junction -Path "$env:USERPROFILE\.config\opencode" -Target "$(Get-Location)\CRUDDY-OPENCODE"

# Option B: Copy contents
Copy-Item -Path "CRUDDY-OPENCODE\*" -Destination "$env:USERPROFILE\.config\opencode\" -Recurse -Force
```

### API Keys

`opencode.json` uses `{env:VAR}` placeholders for API keys. **You must set these environment variables before OpenCode starts:**

| Variable | Provider | Notes |
|----------|----------|-------|
| `MINIMAX_API_KEY` | MiniMax | Required for MiniMax models |
| `OPENCODE_API_KEY` | OpenCode Go | Required for OpenCode Go models |
| `GROQ_API_KEY` | Groq | Required for Groq models |
| `PLAYWRIGHT_MCP_EXTENSION_TOKEN` | Playwright MCP | Optional, for browser automation |

```bash
# Linux/macOS — add to ~/.bashrc or ~/.zshrc
export MINIMAX_API_KEY="your-key-here"
export OPENCODE_API_KEY="your-key-here"
export GROQ_API_KEY="your-key-here"

# Windows PowerShell — add to $PROFILE
$env:MINIMAX_API_KEY = "your-key-here"
$env:OPENCODE_API_KEY = "your-key-here"
$env:GROQ_API_KEY = "your-key-here"
```

**Never commit real API keys to this repo.** The `.gitignore` excludes `.env` files. GitHub's push protection will block commits containing common API key patterns.

### Validation

After installation, verify your config:

```powershell
powershell -NoProfile -File "$env:USERPROFILE\.config\opencode\scripts\validate-config.ps1"
# EXPECT: 87 PASS, 0 FAIL
```

## Architecture

```
.config/opencode/
├── AGENTS.md                   # Master agent routing table
├── opencode.json               # Main config (provider, mcp, plugin list)
├── agents/                     # 25 agent definitions (.md + .yaml)
├── skills/                     # 31 skill packs (each with SKILL.md)
├── plugins/                    # 15 JS plugins (hooks, guards, memory)
├── scripts/                    # 110+ PowerShell utilities
├── rules/                      # 24 rule files (constraints, conventions)
└── factory/
    ├── docs/                   # Architecture & hooks documentation
    ├── planning/               # Specs and acceptance criteria
    └── scripts/                # (excluded — see .gitignore for .venv)
```

### Routing

All requests enter through `main-coordinator` (defined in `agents/main-coordinator.md`), which routes to specialized agents based on intent. See `AGENTS.md` for the full routing table.

### Defensive Plugins

| Plugin | Purpose |
|--------|---------|
| `memory-bridge.js` | Auto-flush session memory on idle, file-based mutex |
| `gate-system.js` | Fork-bomb protection, agent depth tracking |
| `sub-agent-guard.js` | Empty/null safe prompt simplification |
| `checkpoint-guard.js` | Block destructive bash + PowerShell aliases |
| `pre-tool-guard.js` | Block destructive commands before execution |
| `post-tool-guard.js` | Auto-lint/format on file edits |
| `compaction-survival.js` | Per-line try/catch on checkpoint index (resilient to corruption) |
| `session-title-guard.js` | Auto-name sessions on first exchange |

## Key Scripts

```powershell
# Validate the entire config (run after any change)
powershell -NoProfile -File scripts/validate-config.ps1

# Save a checkpoint (now supports empty FilesModified for read-only tasks)
powershell -NoProfile -Command "& scripts/checkpoint-save.ps1 -SessionId 'x' -ProgressPercent 100 -FilesModified '' -Strategy 'read-only' -NextAction 'done'"

# Check token budget (with env var fallback if YAML parser unavailable)
powershell -NoProfile -Command "& scripts/track-tokens.ps1 -Action check -Agent 'code-builder' -Tokens 5000"

# Clean up stale checkpoint files (>24h old, keep 3 most recent)
powershell -NoProfile -File scripts/cleanup-checkpoints.ps1
```

## Portability

This config uses `{env:USERPROFILE}` for paths in `opencode.json` and `$env:USERPROFILE` in PowerShell scripts. After cloning:

- **Windows:** Works out of the box (`%USERPROFILE%` resolves to `C:\Users\<you>`)
- **Linux/macOS:** Either symlink `~/.config/opencode` to the cloned path, or modify the `plugin` array in `opencode.json` to use `~/.config/opencode/plugins/` instead

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgements

Built and battle-tested with OpenCode. Special thanks to the OpenCode community.
