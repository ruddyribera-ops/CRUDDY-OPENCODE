---
name: batch-skill-enrichment
description: Bulk enrich skill files with frontmatter tags, When to Use / Do Not Use sections, trigger phrases, scope boundaries, and deduplication markers. Apply structural upgrades across many skills at once. Use when maintaining a growing skill library.
tags: [skills, maintenance, bulk-edit, frontmatter]
version: 1.0.0
platforms: [windows, macos, linux]
metadata:
  category: productivity
  tags: [skills, frontmatter, triggers, bulk-edit, maintenance]
---

# Batch Skill Enrichment

## When to Use
- After skill audit identifies structural gaps across multiple skills
- Before launching a new project that needs clean trigger routing
- When skills lack `## When to Use` or `## Do Not Use` sections
- When skills have broken/duplicate frontmatter blocks
- When sibling skills have overlapping scope (need boundary notes)
- When skills have empty or missing `description` in frontmatter
- When `tags` frontmatter array is missing
- When a skill is a duplicate of another (need deprecation)

## Do Not Use
- For content-level rewrites of individual skills (use per-skill editing instead)
- For creating new skills from scratch (use `skill-learning` skill)
- For one-off frontmatter fixes (edit the single file directly)
- For skills that already have clean triggers and boundaries

## Procedure

### Phase A — Inventory & Backup
1. Scan all skills:
   ```powershell
   Get-ChildItem -Path "$env:USERPROFILE\.config\opencode\skills" -Recurse -Filter "SKILL.md"
   ```
2. Create timestamped backup of files to be modified:
   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\opencode\_phase_backup_$(Get-Date -Format yyyyMMdd_HHmmss)"
   ```

### Phase B — Frontmatter Normalization
1. For each skill file, check top of file for exactly one YAML frontmatter block:
   - Must be enclosed in `---` fences
   - Must contain `name:` and `description:` keys
tags: [skills, maintenance, bulk-edit, frontmatter]
2. If duplicate frontmatter blocks exist (multiple `---` before real content):
   - Merge into single block keeping the most complete one
   - Remove orphaned `version:` / `---` artifacts
3. If `tags:` array is missing, add it with 2-5 relevant category tags.
4. If `description:` is empty or uses `|` / `>` with no text, write a concise one-liner.
tags: [skills, maintenance, bulk-edit, frontmatter]

### Phase C — Trigger & Boundary Sections
1. Add `## When to Use` section with:
   - 5-15 concrete trigger phrases (literal user-utterable keywords)
   - Command-oriented language ("build a Docker image", "debug N+1 query")
   - Context cues: project phase, file type, error pattern

2. Add `## Do Not Use` section with:
   - Explicit adjacent domains to exclude
   - "For [task], prefer [OTHER_SKILL] instead" boundaries
   - At least 3-5 items per skill

3. For overlapping sibling skills, add scope disclaimers:
   - `For [subset task], prefer [SPECIFIC_SKILL]`
   - `For [superset task], prefer [BROADER_SKILL]`

### Phase D — Deduplication & Deprecation
1. If two skills have identical scope (same procedure, same tools):
   - Choose canonical skill (most complete, better described)
   - Mark other with `status: deprecated` and `replaced-by: <canonical>` in frontmatter
   - Keep minimal body: "This skill is deprecated. Use [canonical] instead."
   - Leave the file in place for backward compat

### Phase E — Validation
1. Verify each modified file has:
   - Single valid frontmatter block
   - `## When to Use` section
   - `## Do Not Use` section
   - `tags` array (if missing was the issue)
2. Quick grep for remaining broken frontmatter:
   ```powershell
   Select-String -Path "*.md" -Pattern "^---$" | Group-Object Path | Where-Object { $_.Count -ne 2 }
   ```
3. Check backup folder integrity.

## Pitfalls
- **Case-insensitive rename on Windows:** `skill.md` → `SKILL.md` can't be done in one step. Use temp name or `Move-Item` with two steps.
- **Empty descriptions:** YAML `description: |` with no following text passes parsing but breaks loader matching. Always check with `Select-String`.
tags: [skills, maintenance, bulk-edit, frontmatter]
- **Over-rewriting:** Resist improving content beyond triggers/boundaries in this phase. Phase 2 is structural only.
- **Collision cascade:** Adding a boundary in one skill means adding a reciprocal boundary in the sibling skill. Check both sides.

## Verification
```powershell
# Count skills with valid frontmatter
Get-ChildItem -Recurse -Filter "SKILL.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '^---\n([\s\S]*?)\n---') {
        "$($_.FullName): frontmatter OK"
    } else {
        "$($_.FullName): BROKEN"
    }
}

# Count When to Use sections
Select-String -Path "*.md" -Pattern "^## When to Use" | Measure-Object

# Count Do Not Use sections
Select-String -Path "*.md" -Pattern "^## Do Not Use" | Measure-Object
```

## Examples
```text
User: "Run Phase 2 across all skills — add triggers and boundaries"
Agent: inventories skills, fixes frontmatter, adds When/Do Not Use sections, creates backup

User: "Git workflow and CI/CD skills overlap — deduplicate"
Agent: adds reciprocal boundary notes, marks one as canonical where appropriate
```

## Quick-Apply Templates

### Standard When to Use (customize per skill)
```markdown
## When to Use
- [trigger phrase 1]
- [trigger phrase 2]
- [trigger phrase 3]
- ...
```

### Standard Do Not Use (customize per skill)
```markdown
## Do Not Use
- [adjacent domain to exclude]
- For [task type], prefer [OTHER SKILL] instead
- ...
```
