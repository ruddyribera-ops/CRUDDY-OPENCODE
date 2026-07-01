# Requirements: Hybrid Memory Retrieval Layer

## Problem Statement

Context window doesn't persist across sessions. OpenAI/Claude give us bigger windows — but bigger isn't better when 80% of the payload is irrelevant history. We need **selective capture + durable storage + relevance-based retrieval** that auto-injects the top-k most relevant memories at session start.

Current state: 22 markdown files in `memory/` — session_log.md, user_preferences.md, project_active.md, TRIGGERS.md, research_poa_*.md (6 files), research_factory_*.md (5 files), reference_*.md (4 files), skill_*.md (2 files), poa_master_prompt.md, poa_2026-06-08.md. No retrieval layer. Everything is read manually, and bigger context windows don't fix the root problem.

## Success Criteria

1. **Retrieval latency ≤ 200ms p95** — measured via `time.time()` around retrieval call. Mem0 paper shows 200ms p95 is achievable at scale. Our local hardware should match or beat that.

2. **Token reduction ≥ 80%** — a typical 8k-token session start should be reducible to ~1.6k tokens by injecting only top-5 relevant memories. Measured by comparing raw prompt size vs. retrieved context size.

3. **Zero external API cost** — all embedding, storage, and retrieval must run locally. No OpenAI, no Anthropic, no hosted vector DB. Verification: `grep -r "openai\|anthropic\|cohere" retrieval/` returns empty.

## Non-Goals

1. **Not building a general-purpose database** — this is for OpenCode session memory, not a replacement for Supabase/PostgreSQL. Only markdown files in `memory/` are in scope.

2. **Not building real-time sync** — memories are immutable once written. Updates use `supersedes` field, not in-place edits. No concurrent writer conflict handling needed.

3. **Not building a RAG pipeline for user documents** — only the OpenCode memory/ files are indexed. User project code is out of scope for MVP.

## Reference: Mem0 Paper Results

From the Mem0 paper (2024):
- **67%** improvement on LOCOMO benchmark vs. vanilla LLMs
- **91%** token reduction via selective memory injection
- **200ms** p95 retrieval latency
- Self-hostable, no external API required

Our target: replicate these properties at solo-developer scale (1 user, ~22 docs, local Windows).

## Our Specific Memory Files (≥5 Named)

| File | Purpose |
|------|---------|
| `session_log.md` | Timestamped history of what happened in each session |
| `user_preferences.md` | User's stated preferences, style, constraints |
| `project_active.md` | Currently active project context, goals, blockers |
| `TRIGGERS.md` | Named trigger phrases that activate OpenCode behaviors |
| `research_poa_*.md` | 6 files: research on planning/approach artifacts |
| `research_factory_*.md` | 5 files: research on agent factory patterns |
| `reference_*.md` | 4 files: reference documentation |
| `skill_*.md` | 2 files: saved skill procedures |
| `poa_master_prompt.md` | Master prompt for POA system |
| `poa_2026-06-08.md` | Dated POA snapshot |

## Constraints

- Windows-compatible (pathlib, no `/tmp`)
- Python 3.12+
- Total spec ≤ 1200 lines across 4 files
- No external API in MVP path
- sentence-transformers `all-MiniLM-L6-v2` (80MB, 384-dim, free, local)

## File Locations

Spec created at: `D:\Temp\opencode\planning\memory-retrieval\`
Implementation target: `~/.config/opencode/memory/` (memory files) + `~/.config/opencode/retrieval/` (new retrieval layer)
