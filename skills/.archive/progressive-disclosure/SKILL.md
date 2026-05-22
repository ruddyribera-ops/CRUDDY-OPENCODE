---
name: progressive-disclosure
description: OpenCode progressive disclosure system for skill content — loads incrementally (L0/L1/L2) to minimize context window waste. Defines the frontmatter schema, level architecture, and loading rules for all skills.
tags: [skills, architecture, documentation, patterns]
---

# Progressive Disclosure — OpenCode Pattern


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

This document defines OpenCode's progressive disclosure system for skills,
allowing skills to load incrementally to minimize context waste.

## Overview


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

Progressive disclosure loads skill content in three levels:

| Level | What Loads | Token Cost | When |
|-------|-----------|------------|------|
| **L0** | Name + description + category | ~100 tokens | Always in context |
| **L1** | Full SKILL.md content | varies | When skill is relevant |
| **L2** | Reference files (references/, templates/) | varies | When specifically needed |

## Implementing Progressive Disclosure


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

### Level 0 — Index Entry
Every skill must have this frontmatter for L0 discovery:

```yaml
---
name: my-skill
description: One-line summary of what this skill does
tags: [skills, architecture, documentation, patterns]
version: 1.0.0
platforms: [windows, macos, linux]
metadata:
  category: devops
  tags: [docker, deployment]
---
```

The coordinator reads `~/.config/opencode/skills/*/SKILL.md` frontmatter only
for L0 (skills_list equivalent).

### Level 1 — Full Skill Content
The SKILL.md body contains:
- When to Use (trigger conditions)
- Procedure (numbered steps)
- Pitfalls (failure modes)
- Verification (test commands)

Full content loaded when skill is selected.

### Level 2 — Supporting Files
For complex skills, use subdirectories:
```
skills/
└── my-complex-skill/
    ├── SKILL.md              # Main instructions (L1)
    ├── references/           # L2: extra docs
    │   ├── api-guide.md
    │   └── troubleshooting.md
    ├── templates/           # L2: output templates
    │   └── output-format.md
    └── scripts/             # L2: helper scripts
        └── setup.sh
```

Load L2 files via skill_view with path:
```
skill_view(name="my-complex-skill", path="references/api-guide.md")
```

## Progressive Disclosure in Agents


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

The main-coordinator loads L0 for all skills at session start.
Specialists load L1 for relevant skills when routed.
L2 loaded on-demand during execution.

## Example: api-patterns Progressive Disclosure


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

### L0 (always available)
```
name: api-patterns
description: REST API design patterns, error handling, response format
tags: [skills, architecture, documentation, patterns]
category: software-development
```

### L1 (when routing to api-patterns)
Full SKILL.md: HTTP status codes, error formats, validation patterns

### L2 (when specifically needed)
```
references/
├── openapi-guide.md
├── rate-limiting.md
└── auth-patterns.md
```

## Skill Format Compatibility with Hermes


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

Hermes implements true Level 0/1/2 loading via its `skills_list()` and
`skill_view(name, path)` tools. OpenCode's file-based approach is compatible —
the coordinator reads SKILL.md frontmatter for L0, full content for L1,
and reference files for L2.

### Implementation Patterns


## When to Use
- Understand OpenCode skill loading architecture
- Design skill frontmatter schema and loading levels
- Optimize skill content for progressive disclosure (L0/L1/L2)
- Reduce context window waste from skill loading

## Do Not Use
- Create new skills (use skill-learning or batch-skill-enrichment)
- Write specific skill content (edit skill directly)
- Configure opencode MCP or providers
- Design agent routing logic

- **L0 discovery**: frontmatter (`name`, `description`, `metadata.category`, `metadata.tags`) — always in context
- **L1 deep loading**: full SKILL.md body loaded when skill is selected by coordinator
- **L2 reference loading**: references/, templates/, scripts/ dirs loaded on demand via read
- **Token budget per level**: L0 ~100 tokens, L1 varies by skill, L2 varies by reference
- **When to promote (L1→L2)**: task enters execution phase and needs specific reference data
- **When to demote (L2→L1)**: reference not used after 3+ tool calls, prune to save context
- **Auto-pruning stale references**: if L2 content isn't referenced in 5+ tool calls, drop from context
