---
name: opencode-delegation
description: Delegate coding tasks to OpenCode specialists. OpenCode has code-builder, bug-fixer, architecture-advisor, and more — each with structured POA → verify → audit workflow.
tags: [opencode, hermes, delegation, agent]
---

# OpenCode Delegation

Delegate coding tasks to OpenCode's specialist agents for structured implementation.

## When to Use

- Task is a coding/implementation request (build, create, add, modify)
- Task needs structured POA → verification → audit workflow
- Task is a bug fix that needs clear reproduction and verification
- Task is a multi-file feature requiring coordination
- You want test-driven verification before declaring done

## OpenCode Specialists

| Specialist | Use For | Triggers |
|------------|---------|----------|
| `code-builder` | New features, implementation, refactoring | build, create, add, implement |
| `bug-fixer` | Bug fixes, error debugging | fix, error, bug, broken |
| `code-analyzer` | Code scanning, health analysis | scan, analyze, structure |
| `architecture-advisor` | Design decisions, tradeoffs | should I, which is better |
| `code-explainer` | Plain-language code explanation | explain, what does |

## How to Delegate

### Via terminal (CLI)
```bash
# Install opencode first if not present
# npm install -g opencode

# Delegate to code-builder
opencode "build a REST API for user authentication"

# Delegate to bug-fixer with specific error
opencode "fix: API returns 500 on /users endpoint"
```

### Via spawn (programmatic)
```python
# If using Hermes Python API
from hermes import AIAgent

opencode = AIAgent(command="opencode", args=["task", "--specialist", "code-builder"])
result = opencode.run_conversation("build a user auth API")
```

## What OpenCode Does

When delegated, OpenCode follows this workflow:

1. **POA (Plan of Action)** — Lists every file to create/modify
2. **Implement** — Writes code following skill patterns
3. **Verify** — Runs lint, tests, build commands
4. **Audit** — Verifies every POA item exists with real content
5. **Report** — Returns structured result with audit block

## Getting Results Back

OpenCode returns to Hermes as a summary:
- What was built/changed
- Files modified
- POA checklist (verified items)
- Verification results (pass/fail)
- Follow-up suggestions

## Skill Mirroring

After OpenCode creates a useful skill, mirror it to Hermes:
```bash
cp ~/.config/opencode/skills/<name>/SKILL.md ~/.hermes/skills/<name>/SKILL.md
```

### Delegation Patterns

- **Task routing rules**: code-builder (new features), bug-fixer (errors), code-analyzer (scanning), architecture-advisor (design), code-explainer (docs)
- **Capability mapping**: route by task type — "fix login" → bug-fixer, "build API" → code-builder, "should I use X" → architecture-advisor
- **Response format expectations**: structured result with POA checklist, verified items, pass/fail per check
- **Error handling**: if specialist times out, retry once; if spec changed mid-task, abort and report
- **Timeout management**: CLI default 120s per command, increase via `--timeout` for long-running tasks

## See Also

- `skills/hermes-integration` in OpenCode — OpenCode's view of Hermes
- `skills/skill-learning` in OpenCode — OpenCode's self-improving skill system
## Do Not Use
- Direct Hermes Agent configuration (use hermes-agent)
- OpenCode-to-Hermes integration setup (use hermes-integration)
- OpenCode skill creation (use skill-learning)
- General agent orchestration
