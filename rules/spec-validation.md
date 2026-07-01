---
name: spec-validation
description: Cross-cutting contract for brownfield spec extraction and validation. Both spec-miner (producer) and architecture-advisor (validator) reference this file. Defines what makes a spec PRELIMINARY vs VALIDATED, evidence requirements, size caps, and the gating flow that prevents hallucinated-consensus failures.
applies_to: spec-miner (producer), architecture-advisor (validator)
triggers: any time a brownfield spec is produced or validated
---

# Spec Validation Contract

## Purpose

Brownfield spec extraction has a known failure mode: **hallucinated consensus**. The producer agent (spec-miner) extracts a spec that *looks* correct but contains fabricated claims. Downstream agents act on the spec as if it were authoritative, building work on a false foundation. Real incidents documented in `rules/agent_rules/dispatch-stalling-prevention.md` lineage.

This contract defines what makes a spec trustworthy vs preliminary, and the gating flow that prevents unverified specs from being treated as authoritative.

---

## Status levels

Every brownfield spec carries exactly one status, declared in its header:

| Status | Meaning | Who can set it | Downstream usage |
|--------|---------|----------------|------------------|
| `PRELIMINARY` | Extracted but unvalidated. May contain fabrications. | `spec-miner` only | Read for context. NEVER act on. NEVER cite as ground truth. |
| `VALIDATED` | Reviewed by `architecture-advisor`. Every claim checked. | `architecture-advisor` only | Cite as ground truth. Safe for downstream decisions. |
| `REJECTED` | Validator found contradictions, missing evidence, or fabrication. | `architecture-advisor` only | Do NOT use. Re-extract with `spec-miner` on a narrower scope. |

A spec without a status header is treated as `PRELIMINARY` by default (fail-safe).

---

## Producer contract (spec-miner obligations)

1. **Always emit `Status: PRELIMINARY`** in every output file's first 5 lines. No exceptions.
2. **Every claim cites evidence**: file path + line range (e.g., `src/auth/jwt.py:42-58`). Claims without evidence are flagged with `[UNVERIFIED]`.
3. **Per-module, not full-system**: split the codebase into modules; produce one set of spec files per module. Cap: 5 modules per dispatch.
4. **Use existing tools, don't re-explore**: use `codebase-memory` MCP for graph queries, `Read` for files, `grep` for searches. Do not run scripts that scan the codebase.
5. **Read-only**: never mutate the source codebase. Output files go to `/tmp/spec-miner/` (or as specified by caller).
6. **Size caps**: each output file ≤ 8 KiB. Truncated files marked `(truncated at 8 KiB)`.
7. **4 file types only**: `architecture.md`, `modules.md`, `data-model.md`, `conventions.md`. No other filenames.
8. **No fabricated data**: if a fact cannot be verified in code, emit `[UNVERIFIED: <reason>]` instead of guessing.

---

## Validator contract (architecture-advisor obligations)

When validating a PRELIMINARY spec, `architecture-advisor` MUST:

1. **Read all 4 spec files** before making any judgment.
2. **Spot-check 20% of citations** by opening the cited file:line and confirming the claim matches the code. Random sample, not cherry-picked.
3. **List every `[UNVERIFIED]` flag** in the validation report. Do not auto-trust them.
4. **Verify status header** is present and matches the spec's actual state (PRELIMINARY if unvalidated, VALIDATED only after this review).
5. **Check size caps**: any file > 8 KiB is auto-flagged for re-extraction.
6. **Cross-check with codebase-memory** if available: compare spec-miner's claims against the indexed graph. Discrepancies go in the validation report.
7. **Produce a validation report** at `/tmp/spec-miner/validation-<module>.md` containing:
   - Status transition (`PRELIMINARY` → `VALIDATED` or `REJECTED`)
   - Spot-check results (each: pass / fail / partial)
   - List of `[UNVERIFIED]` claims and whether they could be verified
   - Discrepancies with codebase-memory
   - Recommendation: VALIDATE, REJECT (with reason), or PARTIAL (which sections pass)

---

## Gating flow

```
[USER REQUEST: brownfield spec needed]
   ↓
main-coordinator → spec-miner (mode: subagent)
   ↓
spec-miner produces PRELIMINARY spec → /tmp/spec-miner/<module>/
   ↓
main-coordinator → architecture-advisor (mode: subagent)
   ↓
architecture-advisor validates, writes report, sets status
   ↓
[IF VALIDATED] downstream agents can cite the spec as ground truth
[IF REJECTED] spec-miner re-runs on narrower scope
```

**Hard rule**: No agent (including main-coordinator) may skip the architecture-advisor validation step. The spec stays `PRELIMINARY` forever until validated.

---

## What this prevents

- **Hallucinated consensus**: spec-miner produces confident-but-wrong specs → validator catches fabricated claims
- **Silent drift**: spec used as ground truth without verification → validator's spot-check catches drift
- **Full-system dumps**: spec-miner tries to extract everything at once → per-module cap forces focused extraction
- **Out-of-date specs**: spec extracted once and used forever → status header + revalidation requirement forces freshness check

---

## Cross-references

- `agents/spec-miner.md` — producer agent (follows producer contract above)
- `agents/architecture-advisor.md` — validator agent (follows validator contract above)
- `rules/agent_rules/dispatch-stalling-prevention.md` — incident lineage
- Augment Code spec-driven development guide (Mar 2026): change-level specs, not full-system
- Cogent Infotech Multi-Agent Orchestration Failure Playbook (Mar 2026): Hallucinated Consensus failure mode