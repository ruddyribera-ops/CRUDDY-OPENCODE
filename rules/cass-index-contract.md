---
name: cass-index-contract
description: Contract for CASS indexer (scripts/cass-index.ps1). Defines what entries must contain, when extraction runs, failure modes, and recovery rules. Both cass-index.ps1 (producer) and any consumer reading memory/cass/index.jsonl (consumers) honor this. Pairs with the loop-operator-safety and spec-validation contracts.
applies_to: cass-index.ps1, auto-memory.ps1, any agent reading CASS index
triggers: any time session_log.md changes, any time CASS index is queried
---

# CASS Index Contract

## Purpose

CASS (Coding Agent Session Search) indexes session log entries for fast lookup. Without a contract:
- Indexer silently fails (the Extract-Terms bug we fixed — was broken for years)
- Index format drifts (entries have inconsistent shape)
- Consumers can't trust the data (different agents see different fields)
- Recovery is unclear (what to do if index is corrupt)

This contract defines invariants, producer obligations, consumer obligations, and recovery.

---

## Entry schema (required)

Every entry in `memory/cass/index.jsonl` MUST have these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string (12-char hex) | YES | Unique entry ID |
| `task` | string | YES | Task name (matches session_log.md row) |
| `agent` | string | YES | Agent name |
| `result` | string | YES | Result (Done | FAIL | PASS | etc.) |
| `tokens` | string | YES | Estimated tokens (e.g., "~500") |
| `date` | string (YYYY-MM-DD) | YES | Date of task |
| `project` | string | YES | Project name or "global" |
| `terms` | array of strings | YES | Search terms (extracted via Extract-Terms) |
| `indexed_at` | string (ISO 8601) | YES | When this entry was indexed |

Optional fields: `session_name`, `task_type`, `files_changed`.

**Invariant:** Every entry has all required fields. If extraction would produce a partial entry, skip it instead.

---

## Producer contract (cass-index.ps1)

1. **Read session_log.md**, extract task table rows
2. **Skip noise entries**: empty task names, header rows ("Task", "Result", "Tokens Est")
3. **Extract terms** via `Extract-Terms` function (case-sensitive: defined as a function BEFORE call site)
4. **Build entry** with all required fields populated
5. **Deduplicate** by hash of `task + agent + result`
6. **Append** new entries to `memory/cass/index.jsonl` (NOT overwrite)
7. **Update meta** file `memory/cass/meta.json` with stats

### Failure modes

| Failure | Behavior |
|---------|----------|
| session_log.md missing | Log to console, exit 0 (no-op, not an error) |
| Task row missing required fields | Skip row, log to hook-errors.log |
| Extract-Terms fails on row | Skip row, continue |
| index.jsonl write fails | Log error, abort (don't partial-write) |
| meta.json write fails | Log warning, continue (stats not critical) |

### Idempotency

Running cass-index.ps1 multiple times MUST be safe:

- No duplicate entries (deduplication by hash)
- meta.json reflects current total, not additive
- Append-only writes (never overwrite existing entries)

---

## Consumer contract (any agent reading CASS)

1. **Treat index as advisory**: not all tasks are indexed; some may be partial
2. **Cross-reference with session_log.md** for canonical truth
3. **Don't act on missing entries**: if a task isn't in CASS, it may just not be indexed yet
4. **Limit query scope**: large indexes can be slow; use date/project filters

---

## Index integrity invariants

The following MUST be true at all times (verified by validators):

1. **No duplicate `id` values** across all entries
2. **All entries have required fields** (per schema above)
3. **`indexed_at` is ISO 8601** (parseable by `[DateTime]::Parse`)
4. **`terms` is non-empty array** (no entries with 0 terms — indicates extraction failed)
5. **File is valid JSONL** (one valid JSON object per line)

Run `scripts/validate-cass-index.ps1` (TODO) to verify.

---

## Failure recovery

### Index corrupt (invalid JSONL, missing fields)

Detection: `cass-search.ps1` fails to parse any line

Recovery:
1. Stop reading index (don't partial-parse)
2. Log to hook-errors.log
3. Fall back to `session_log.md` for canonical data
4. Re-run `cass-index.ps1` to rebuild (after fixing source corruption)
5. NEVER auto-clear the index (data loss risk)

### Index stale (entries > 30 days old)

Behavior: index returns stale results. Consumer must check `indexed_at` and warn if > 7 days.

NOT auto-cleaned. Manual cleanup only via explicit user request.

### Index size > 10MB

Behavior: search performance degrades.

Recovery:
1. Warn user
2. Offer to archive entries older than 90 days to `memory/cass/archive.jsonl`
3. Index continues with active entries
4. Original file backed up before archive

---

## What this prevents

| Risk | Mitigation |
|------|------------|
| Silent indexer failures (Extract-Terms bug) | Producer contract requires function to be defined BEFORE call site |
| Inconsistent entry shape | Required fields enforced; partial entries skipped |
| Consumer confusion | Schema documented; advisory-only index |
| Index corruption without recovery | Detect+fallback to session_log.md; never auto-clear |
| Index grows unbounded | Size cap warning; user-driven archival |

---

## Cross-references

- `scripts/cass-index.ps1` — producer
- `scripts/cass-search.ps1` — consumer
- `scripts/auto-memory.ps1` — triggers cass-index on session.idle
- `rules/loop-operator-safety.md` — sibling contract (different domain, same structure)
- `rules/spec-validation.md` — sibling contract

---

## Status

**APPROVED — 2026-06-29.** Adopted as part of audit fixup sprint. Paired with the Extract-Terms bug fix (Batch 1.3 of audit fixup).