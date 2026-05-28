---
name: skill-learning
description: Agent-managed skill creation — save successful workflows as reusable skills. Auto-triggered after complex tasks (5+ tool calls). Integrates with Hermes Agent's skill system.
tags: [skills, learning, self-improvement, creation]
---

# Skill Learning — Self-Improving Skill Creation

## When to Use

Trigger this skill when:
- A complex task succeeded after 5+ tool calls
- You hit errors or dead ends and found the working path
- The user corrected your approach and it worked
- You discover a non-trivial workflow that could apply to future tasks
- The user says "remember this procedure" or "save this as a skill"

**Do NOT trigger for:**
- Simple one-offs (single tool call, trivial fix)
- Tasks that failed completely (save failures as lessons_learned.md instead)
- Tasks that were abandoned before completion

## How It Works

This skill implements a **progressive disclosure skill creation** pattern inspired by Hermes Agent:

### Level 0 — Detection (automatic)
Track tool call count per task. After 5+ calls, evaluate if the workflow was non-trivial.

### Level 1 — Skill Draft
After task completion, propose saving the workflow. Draft SKILL.md with:
- **Trigger conditions** (when should this skill be used?)
- **Procedure** (numbered steps, exact commands)
- **Pitfalls** (known failure modes and workarounds)
- **Verification** (how to confirm it worked)

### Level 2 — Validation & Storage
- Confirm with user before creating
- Write to `~/.config/opencode/skills/<category>/<skill-name>/SKILL.md`
- Add `references/` dir if supporting files are needed

## Skill Creation Protocol

### Step 1: Detect Non-Trivial Task
After any task completes, briefly consider:
- How many distinct tool calls were made?
- Was there a recovery from error or dead-end?
- Did the user teach you something that worked?
- Could this workflow apply to future tasks?

### Step 2: Draft the Skill
Generate SKILL.md with this template:

```markdown
---
name: [skill-name]
description: [2-3 sentence summary of what this skill does]
tags: [skills, learning, self-improvement, creation]
version: 1.0.0
platforms: [windows, macos, linux]
---

# [Skill Title]

## When to Use
[Trigger conditions — what situations activate this skill? Be specific.]

## Procedure
1. [Step 1 with exact commands where applicable]
2. [Step 2]
3. [Step 3]

## Pitfalls
- [Known issue 1] → [Workaround]
- [Known issue 2] → [Workaround]

## Verification
[How to confirm the skill worked — test commands, expected output patterns]
```

### Step 3: Propose to User
```
"Should I save this as a skill? I'd call it `X` — it handles [use case]."
```
- If yes → create the skill file
- If no → skip, don't insist

### Step 4: Write the File
Create directory and SKILL.md:
```
~/.config/opencode/skills/<category>/<skill-name>/SKILL.md
```

Valid categories: `devops`, `data-science`, `mlops`, `software-development`, `productivity`, `research`, `creative`

### Step 5: Verify Write
Read back the file to confirm it was written correctly.

### Step 6: Update SKILLS_INDEX (MANDATORY after skill creation)
After creating or modifying a skill SKILL.md file, regenerate the skills index:

1. Run: `powershell -File $HOME\.config\opencode\scripts\skill-version-check.ps1`
2. Verify the new skill appears in the index
3. If the script fails: manually add the skill entry to `skills/SKILLS_INDEX.json`

**Why:** The SKILLS_INDEX is the registry all agents use for skill discovery. An index entry missing = a skill invisible to the system.

## Hermes Skill Compatibility

Hermes skills use the same SKILL.md format. To export to Hermes:
1. Copy `~/.config/opencode/skills/<name>/SKILL.md`
2. To `~/.hermes/skills/<name>/SKILL.md`

Hermes-specific fields (`metadata.hermes.*`) will be silently ignored by OpenCode,
but OpenCode skills work in Hermes as long as they have `name` and `description`.

## Skill Update Protocol

When using a skill and it fails or has gaps:
- **Patch immediately** using the edit pattern
- Document the failure in the Pitfalls section
- After 3+ patches, bump the version number

## Integration with Hermes

If Hermes Agent is running locally (WSL/Linux):
- Skills created here can be mirrored to `~/.hermes/skills/`
- Hermes can also use OpenCode skills via external_dirs config
- The `hermes-integration` skill provides the bridge

See also: `skills/hermes-integration/SKILL.md` for the complementary integration layer.

### Skill Creation Best Practices

- **Structure**: frontmatter → overview → triggers → workflow → rules → resources
- **Quality Gates**: version in frontmatter, minimum 50 lines, concrete examples with code
- **Triggers**: keyword coverage across languages, language-agnostic trigger phrases
- **Frontmatter**: name, description, version, platforms, metadata (category, tags)
- **Testing**: validate-skill.js for structural checks, skill-version-check.ps1 for version drift
- **Hermes**: skill.md compatible format, bidirectional sync via cp/mirror
## Do Not Use
- Bulk skill enrichment across many files (use batch-skill-enrichment)
- OpenCode configuration (use customize-opencode)
- Agent routing decisions (handled by main-coordinator)
- Writing skill content without tool-based workflow
