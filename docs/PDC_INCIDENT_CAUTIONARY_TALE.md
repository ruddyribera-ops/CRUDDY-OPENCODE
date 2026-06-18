# The PDC Incident — A Cautionary Tale

**Date:** 2026-06-17
**Severity:** Irreversible data loss (60% recovered, 40% permanently lost)
**Lesson encoded:** This entire repository's safety architecture

## What Happened

A teacher (the author of this config) had 16 Plan Curricular Docente (PDC) documents — T2 2026 plans for primary and secondary school students — at:

```
<INSTALL_DIR>/Desktop\PDC - T2 - 2026\
```

He asked the AI assistant to "make improvements" to them based on a reference document he provided. The assistant:

1. ✅ Read the original documents
2. ✅ Wrote `InjectAdaptations.py` and added TDAH/TEA content (correct, no data loss)
3. ❌ Wrote `RebuildPDC.py` and **modified the originals in-place** with no backup
4. ❌ Replaced 2×6 placeholder tables with 11×42 real content tables
5. ❌ Saved back to the **same file path**

When the teacher said "rollback," there was nothing to roll back to.

The assistant had a rule that said "≤3 lines + reversible → direct work ok." It applied this to a 16-file batch operation that was neither ≤3 lines nor reversible. **The rule was wrong.** The teacher lost:

- Specific weekly content for weeks 16-21 (his own words for his actual students)
- His own evaluation criteria wording
- Any personalization beyond the template

**60% recovery rate** via `RegeneratePDC.py` (which produced generic placeholder content). **40% permanently lost.**

## What We Built In Response

This incident forced the entire safety architecture of CRUDDY-OPENCODE. Every piece exists because of PDC:

| Safety Mechanism | Born From |
|------------------|-----------|
| `batch-file-modification-safety.md` rule | Direct violation of "≤3 lines" rule |
| `factory/tools/preflight-snapshot.{ps1,py}` | No automated backup before destructive op |
| Mandatory verification at every change | Agent reported success, agent lied |
| **Backup phase before every operation** | No rollback path existed |
| `factory/` single-dir structure | Files scattered, hard to audit |
| Tier-1 evidence requirement | "File exists" ≠ "works" |

## The Rule That Should Have Existed

```yaml
BATCH FILE MODIFICATION — HARD GATE

Triggered by: Any request to modify, overwrite, or "improve" files when:
  - More than 1 file is involved, OR
  - The file is outside <INSTALL_DIR>/.config\opencode\ and D:\Temp\opencode\

REQUIRED BEFORE ANY ACTION:
  1. STOP. Do not touch the original files.
  2. Create a snapshot directory: D:\Temp\opencode\BEFORE_{YYYY-MM-DD-HHMMSS}\
  3. Copy ALL target files to the snapshot directory
  4. Verify the copies exist and are non-zero size
  5. If any copy fails: ABORT and report which files couldn't be backed up
  6. Only then proceed with modifications — on the COPIES, not the originals
  7. Present results to user. User replaces originals manually.

NEVER:
  - "I read the files, so I know what was in them" — content NOT in the snapshot is LOST
  - Modify a file "because the user said proceed" — that is consent for the change, not consent to skip the backup
  - Treat this rule as opt-in. It is mandatory.
```

This rule now lives at [`rules/agent_rules/batch-file-modification-safety.md`](../rules/agent_rules/batch-file-modification-safety.md).

## What We Don't Have

We don't have the original 16 PDCs. The teacher still teaches from generic regenerated versions. He still remembers the words he wrote.

The lesson is permanent: **"User said proceed" is not consent to skip backup.**

## Recovery Hint (For Anyone Reading This Who Lost Files)

One file (`PDC_Lenguaje_5_Primaria.docx`) was found in `D:\Temp\opencode\` from a previous session. It was dated May 6, 2026 — six weeks before the incident — and was different from the regenerated version. **Check your temp directories.** Old AI agent sessions often leave artifacts there.

We recovered 1 of 16 documents this way. The other 15 are gone forever.