---
name: skill-location-junction
description: Documents that ~/.claude/skills/ is a junction (symlink) to ~/.config/opencode/skills/ on this Windows setup. The "54 skill name collisions" reported by health-check-report item 11 are FALSE POSITIVES — both paths point to the same content.
applies_to: health-check-report readers, future audit scripts
triggers: any skill collision or duplicate detection
---

# Skill Location Junction — Documentation

## Discovery (2026-06-29, audit fixup sprint)

The user's `~/.claude/skills/` directory is a Windows **Junction** (symlink) pointing to `~/.config/opencode/skills/`:

```
LinkType: Junction
Target:   C:\Users\Windows\.config\opencode\skills
```

Both paths resolve to the same content. Verified by SHA256 hash comparison:

```
cs-fundamentals/SKILL.md hash:
  opencode/skills: 9DAE30FB9B2FA199738CFEC3D96040D51EE557FC5F1ED672AAE24A090C728C80
  claude/skills:   9DAE30FB9B2FA199738CFEC3D96040D51EE557FC5F1ED672AAE24A090C728C80
  Identical: True
```

## Why this matters

The `health-check-report.md` (item 11) reports:

> "54 of 54 local skills collide with ~/.claude/skills/ names — both directories load and may shadow each other"

This is a **false positive**. The health-check script doesn't recognize Windows junctions and treats them as separate directories.

## Resolution

**No action required.** The junction is intentional — it allows Claude Code (which uses `~/.claude/skills/`) and OpenCode (which uses `~/.config/opencode/skills/`) to share the same skills without duplication.

## Recommendation for future audits

When checking for skill collisions:
1. Detect junctions via `[System.IO.DirectoryInfo].LinkTarget`
2. Skip junction targets in collision counts
3. Report: "N skills loaded (X via junction, Y direct)"

## Also: project-generator PROMPT templates are OUTPUTS

While investigating this, found that `agents/project-generator.md` references `PROMPT-0-FOUNDATIONAL-CONTRACT.md`, `PROMPT-X-CROSS-CUTTING-RULES.md`, etc. These are NOT missing templates — they are **output filenames** that project-generator creates when scaffolding a new project.

Lines 873, 915, 941 in project-generator.md explicitly state:
- "**Generates file:** `PROMPT-0-FOUNDATIONAL-CONTRACT.md`"
- "`[BUILDER]` drafts `PROMPT-N-PHASE-NAME.md`"

So no missing-template problem exists. The original audit finding was a false positive.

---

## Status

**DOCUMENTED — 2026-06-29.** Future audit scripts should detect junctions to avoid this false positive.