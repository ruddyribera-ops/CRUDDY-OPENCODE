---
name: codemap
description: "Fast codebase orientation via markdown overview. Generates two deterministic markdown files (codemap.md + modules.md, each capped at 8 KiB) in seconds using pure stdlib Python. Use when cold-starting on a new or unfamiliar codebase, need a quick structural overview, want a shareable markdown doc, or onboarding to a project. Triggers: new repo orientation, codebase map, fast overview, what's in this repo, give me a tour, summarize this repo, codebase overview. NOT for deep graph queries (use codebase-memory MCP), specific function lookup (use grep or Read), health/quality analysis (use code-analyzer), security review (use cybersecurity), or design decisions (use architecture-advisor)."
---

# Codemap — Fast Codebase Orientation

## When to use this

Load this skill when:

- Cold-starting on a new or unfamiliar codebase
- Need a quick structural overview in seconds (not minutes)
- Want a shareable markdown doc of a codebase
- Onboarding to a project before deep work

Do NOT use this skill when:

- Need specific function or file lookup → use `grep` or `Read` tool
- Need deep graph queries, call graphs, or symbol navigation → use `codebase-memory` MCP tools
- Need health or quality analysis → dispatch `code-analyzer`
- Need security review → dispatch `cybersecurity`
- Need architectural decisions → dispatch `architecture-advisor`

---

## What it produces

Two deterministic markdown files (pure stdlib Python, no LLM call):

| File | Contents | Size cap |
|------|----------|----------|
| `codemap.md` | Detected languages, manifest files, entry points, file type counts, largest files | 8 KiB |
| `modules.md` | Top-level directory structure + cross-references to other agents | 8 KiB |

Total output: ≤16 KiB. Always fits in a single context block.

---

## Usage

```powershell
python "$env:USERPROFILE\.config\opencode\skills\codemap\scripts\generate.py" <repo_path> --output-dir <out_dir>
```

Default `--output-dir` is the current directory. Files are written as `codemap.md` and `modules.md`.

JSON summary printed to stdout (languages detected, entry point count, file sizes).

---

## Core principles

1. **Deterministic** — pure stdlib Python. No LLM calls, no API hits, no network. Same input → same output. No flakiness.
2. **Fast** — runs in seconds. Skips `node_modules`, `.venv`, `venv`, `__pycache__`, `.git`, `dist`, `build`, `.next`, `target`.
3. **Bounded** — 8 KiB hard cap per output file. Truncated output is marked `(truncated at 8KiB)`. Listings capped at 50 items.
4. **Complementary, not replacement** — explicitly orthogonal to `codebase-memory` (graph deep queries), `code-analyzer` (health), `architecture-advisor` (design). See Cross-references below.
5. **Read-only on input** — never modifies the source codebase. Only writes the two output files.

---

## Cross-references

After generating a codemap, decide what to do next based on what you learned:

- **Need symbol-level navigation** (find a specific function, trace a call) → use `codebase-memory_search_graph` or `codebase-memory_get_code_snippet`
- **Need health or quality assessment** (test coverage, debt, complexity) → dispatch `code-analyzer`
- **Need security review** (auth, secrets, injection risk) → dispatch `cybersecurity`
- **Need architectural decisions** (when to refactor, which pattern to use) → dispatch `architecture-advisor`
- **Need a deep semantic overview** (more than structure) → use `codebase-memory_get_architecture` (slower, richer)

---

## When NOT to ship a codemap

- Empty repos (<5 files) — just read the files directly
- Repos you already have a `codebase-memory` index for — use that instead
- Single-file scripts — overkill
- Production deployment decisions — codemap is for orientation, not action