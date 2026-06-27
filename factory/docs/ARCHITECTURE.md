# OpenCode System Architecture

## Overview

```
opencode config root: ~/.config/opencode/
```

## Directory Map

```
.config/opencode/
├── opencode.json          # Main config (never moved)
├── AGENTS.md              # Agent routing table (never moved)
├── plugins/               # Plugin JS files (never moved)
│   └── session-start-memory.js  ← fires session_start.py on boot
├── skills/                # Agent skill definitions (never moved)
├── agents/                # Agent configs (never moved)
├── rules/                 # Challenger rules (never moved)
├── memory/                # Runtime memory store (never moved)
├── gates/                 # Runtime gate markers (never moved)
├── factory/               # ★ CONSOLIDATED system code
│   ├── README.md
│   ├── INDEX.md
│   ├── scripts/
│   │   ├── autoresearch/  # Nightly auto-research (karpathy-style)
│   │   └── memory_retrieval/  # Hybrid BM25+cosine+graph search
│   ├── hooks/
│   │   └── session_start.py   # Session-start handler
│   ├── planning/
│   │   ├── memory-retrieval/  # v1 blueprint + docs
│   │   └── memory-v2/         # v2 migration plan
│   └── docs/
│       ├── HOOKS.md           # Hook reference
│       └── ARCHITECTURE.md    # This file
```

## Data Flow

### Session Start Flow
```
opencode boot
  → plugins/session-start-memory.js
    → reads CONFIG_ROOT from opencode.json
    → calls: python factory/hooks/session_start.py
      → runs memory retrieval (last conversation summary)
      → writes result to memory/session-start-memory.log
      → creates gates/.session-start-memory.done marker
```

### Nightly Autoresearch Flow
```
schtasks (02:00 daily)
  → factory/scripts/autoresearch/nightly_run.ps1
    → python factory/scripts/autoresearch/iterate.py
      → prepare.py (eval, read-only)
      → train.py (pointer update)
      → iterate.py (check convergence)
    → results written to memory/autoresearch_nightly.log
```

### Memory Retrieval Flow
```
opencode prompt triggers "remember" / "last time"
  → python -m memory_retrieval query "..."
    → cli.py → retriever.py → graph.py
    → BM25 + cosine hybrid search over memory/ files
    → returns top-k results
```

### Watcher Daemon Flow
```
watcher_run.ps1 (manual or startup)
  → factory/scripts/memory_retrieval/watcher.py
    → watches memory/ for changes
    → auto-indexes new/modified files
    → updates memory_retrieval index store
```

## Path Resolution

| Component | Resolves to |
|-----------|-------------|
| `opencode.json` `CONFIG_ROOT` | `~/.config/opencode` |
| `session-start-memory.js` PYTHON_SCRIPT | `factory/hooks/session_start.py` |
| `nightly_run.ps1` ITERATE_SCRIPT | `factory/scripts/autoresearch/iterate.py` |
| `cli.py` DEFAULT_ROOT | `..parent.parent.parent.parent` = opencode root |
| `memory_retrieval` index | `memory/` (runtime data, not in factory) |
| `memory_retrieval` logs | `memory/` (runtime data, not in factory) |

## Runtime vs. Source

- **Source code** lives in `factory/` (checked into backup)
- **Runtime data** lives in `memory/`, `gates/` (not in factory, not backed up as source)
- **Config** lives at root level (`opencode.json`, `AGENTS.md`)