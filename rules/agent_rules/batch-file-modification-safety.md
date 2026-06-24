---
description: Mandatory snapshot backup before any batch file modification — prevents permanent data loss
condition: modify|overwrite|rebuild|rewrite.*file|batch.*file
scope: "tool:edit(**/*), tool:write(**/*)"
severity: error
triggered_by: "Batch file modification without snapshot backup"
exception_scope: "C:\Users\Windows\.config\opencode\, D:\Temp\opencode\"
---

# BATCH FILE MODIFICATION — HARD GATE

**Mandatory snapshot backup before ANY operation that modifies, overwrites, or rebuilds files.**

## Trigger Conditions

This rule is triggered when ANY of:
- **More than 1 file** is involved in the modification
- Target file is **outside** `C:\Users\Windows\.config\opencode\` and `D:\Temp\opencode\`
- Any `python-docx`, `openpyxl`, or library that **overwrites in-place** without version history

## Required Steps (MANDATORY — do not skip)

```
1. STOP — do not touch the original files
2. Create snapshot: D:\Temp\opencode\BEFORE_{yyyy-MM-dd-HHmmss}\
3. Copy ALL target files to snapshot using Copy-Item -Recurse
4. Verify copies exist and are non-zero size
5. If any copy fails → ABORT immediately, report which files couldn't be backed up
6. ONLY THEN proceed — modify the COPIES, not the originals
7. Present results to user. User replaces originals manually.
```

## Snapshot Directory Naming

```
D:\Temp\opencode\BEFORE_2026-06-17-143052\
```

## NEVER

- "I read the files so I know what was in them" — content NOT in snapshot is **PERMANENTLY LOST**
- Modify because "user said proceed" — that's consent for the change, NOT consent to skip backup
- "It's only 16 files, I'll be careful" — 16 files were destroyed on 2026-06-17
- Use python-docx, openpyxl, or any library that overwrites without backup-first
- Treat this as opt-in — it is **mandatory**

## Historical Context

**2026-06-17 PDC Destruction Incident:** 16 teacher planning documents destroyed. ~40% of user-written content permanently lost. Root cause: in-place modification without creating backup copies first.

## Correct Workflow

```
❌ WRONG: Open file → modify → save (overwrites original)
✅ RIGHT: Copy to snapshot → modify copy → present to user
✅ RIGHT: Copy to D:\Temp\opencode\BEFORE_2026-06-17-143052\ → modify copies → user manually replaces originals
```

This rule is non-negotiable. Violation = immediate abort + report to user.
