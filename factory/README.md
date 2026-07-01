# Factory — System Code Consolidation

This directory consolidates all system-level code built for OpenCode — scripts, hooks, planning docs, and architecture references.

## What is this?

`factory/` is the single source of truth for operational code that:
- Runs on a schedule (autoresearch nightly job)
- Fires on session events (session_start.py hook)
- Is invoked by plugins (memory_retrieval CLI + watcher)
- Documents system architecture and planning decisions

## Subdirectories

| Path | Purpose |
|------|---------|
| `scripts/autoresearch/` | Karpathy-style auto-research loop (prepare → train → iterate). Runs nightly via schtasks. |
| `scripts/memory_retrieval/` | Hybrid BM25+cosine+graph memory search. CLI + watcher daemon. |
| `hooks/session_start.py` | Session-start hook — runs memory retrieval on opencode boot. |
| `planning/memory-retrieval/` | v1 memory system blueprint, acceptance criteria, risks |
| `planning/memory-v2/` | v2 memory system migration plan, gap analysis, roadmap |
| `docs/` | Architecture diagrams, hook reference |

## Key Files

- `scripts/autoresearch/iterate.py` — main autoresearch entry point
- `scripts/autoresearch/nightly_run.ps1` — scheduled task wrapper
- `scripts/memory_retrieval/cli.py` — `python -m memory_retrieval` entry point
- `scripts/memory_retrieval/watcher.py` — file-system watcher daemon
- `hooks/session_start.py` — plugin-triggered session start handler
- `docs/ARCHITECTURE.md` — full system map

## Not here

These live at the OpenCode root level (not consolidated):
- `opencode.json` — main config
- `AGENTS.md` — agent routing table
- `plugins/` — plugin implementations
- `skills/` — agent skill definitions
- `agents/` — agent configurations
- `rules/` — challenger rules
- `memory/` — runtime memory store
- `gates/` — runtime gate markers