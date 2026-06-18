---
name: hermes-agent
description: Enable Hermes Agent to delegate coding tasks to OpenCode specialists and share skills/memory bidirectionally
tags: [ai, agent, hermes, integration]
---

# Hermes Agent Integration for OpenCode

This skill enables Hermes Agent to delegate coding tasks to OpenCode specialists
and share skills/memory bidirectionally with the OpenCode coordinator.

## When to Use

- User asks a coding task that would benefit from OpenCode's specialist routing
- You need OpenCode's structured POA → implementation → audit workflow
- You want to mirror a skill to OpenCode's skill directory
- You want to read OpenCode's memory/lessons for context

## How to Delegate to OpenCode

OpenCode runs as a Node.js CLI tool. From Hermes terminal:

```bash
# Delegate a coding task to OpenCode
opencode "Fix the login bug in my API"

# Or run OpenCode with a specific specialist
opencode --task bug-fixer --prompt "Fix the login bug"

# OpenCode will handle routing, specialists, POA, verification
```

## Available OpenCode Specialists

| Specialist | Handles | Trigger |
|------------|---------|---------|
| code-builder | Implementation, new features | build, create, add, implement |
| bug-fixer | Bug fixes, error debugging | fix, error, bug, broken |
| code-analyzer | Code health, scanning | scan, analyze, structure |
| code-explainer | Plain-language explanations | explain, what does |
| architecture-advisor | Design decisions, tradeoffs | should I, which is better |
| project-generator | New projects from scratch | new project, desde cero |

## Skill Mirroring (Hermes → OpenCode)

```bash
# Copy a Hermes skill to OpenCode's skills directory
cp ~/.hermes/skills/my-skill/SKILL.md ~/.config/opencode/skills/my-skill/SKILL.md

# Or use the hub
hermes skills install ~/.config/opencode/skills/my-skill/SKILL.md --name my-skill
```

## Memory Bridge

Hermes memory: `~/.hermes/memories/MEMORY.md`
OpenCode memory: `~/.config/opencode/memory/`

To share:
```bash
# Let Hermes read OpenCode's memory
ln -s ~/.config/opencode/memory/*.md ~/.hermes/memories/opencode_*.md

# Let OpenCode read Hermes's memory
ln -s ~/.hermes/memories/MEMORY.md ~/.config/opencode/memory/hermes_memory.md
```

## Session Search Bridge

Hermes stores sessions in SQLite with FTS5:
```bash
~/.hermes/sessions/*.db
```

OpenCode can query Hermes sessions for context:
```bash
sqlite3 ~/.hermes/sessions/$(ls -t ~/.hermes/sessions/*.db | head -1) \
  "SELECT content FROM messages WHERE content LIKE '%keyword%' LIMIT 5;"
```

## Integration Notes

- OpenCode uses the same SKILL.md format as Hermes (agentskills.io standard)
- OpenCode's `§` delimiter in MEMORY.md is compatible with Hermes memory format
- OpenCode skills at `~/.config/opencode/skills/` can be added to Hermes's external_dirs
- Hermes's skill_manage tool can create skills compatible with OpenCode

### Integration Patterns

- **Skill sharing**: bidirectional mirror via `cp`, frontmatter translation (hermes `metadata.hermes.*` fields silently ignored by OpenCode)
- **Memory sync**: shared memory files via symlinks, conflict resolution by timestamp (newest wins)
- **Delegation**: OpenCode → Hermes (scheduling, messaging, cron), Hermes → OpenCode (coding, multi-file features, POA workflow)
- **CLI Setup**: `npm install -g opencode-cli`, `hermes` in PATH, API key management via env vars

## See Also

- `skills/skill-learning` in OpenCode — OpenCode's skill creation system
- `skills/hermes-integration` in OpenCode — OpenCode's view of Hermes integration
## Do Not Use
- General OpenCode configuration (use customize-opencode)
- Skill creation (use skill-learning)
- Integration between OpenCode and Hermes (use hermes-integration)
- Agent routing or coordination (handled by main-coordinator)
