---
name: hermes-integration
description: Bridge to spawn Hermes Agent as a subagent for complex tasks. Enables OpenCode to delegate to Hermes for scheduling, messaging gateway tasks, or Hermes's self-improving skill system.
tags: [hermes, integration, bridge, agent]
---

# Hermes Agent Integration

## Purpose

Enable OpenCode to spawn Hermes Agent as a subagent for tasks that benefit from:
- **Hermes's self-improving skill system** (agent creates/updates skills from experience)
- **Hermes's messaging gateway** (Telegram/Discord/Slack delivery of results)
- **Hermes's cron scheduling** (timed task execution)
- **Hermes's session search** (FTS5 SQLite across all conversations)

## When to Use

Route TO Hermes when user says:
- "Schedule this for tomorrow"
- "Remind me about this via Telegram"
- "Remember this workflow for next time" (let Hermes auto-skill it)
- "What did we discuss about X last week?" (Hermes session search)

Route TO Hermes AS a subagent for:
- Multi-step tasks where Hermes's skill system could learn and improve
- Long-running tasks that could benefit from Hermes's context compression
- Tasks requiring Docker/SSH/Modal backend (Hermes has these)

## Prerequisites

- Hermes Agent installed (Linux/WSL/macOS)
- `hermes` command in PATH
- Or Hermes running at `http://localhost:30000`

## How to Spawn Hermes

Use the Task tool with `subagent_type=general` and pass this system prompt:

```
You are Hermes Agent, spawned by OpenCode as a subagent.
Your task: [TASK DESCRIPTION]
Bridge back: When done, summarize results for OpenCode coordinator.
Available tools: terminal, read_file, write_file, web_search, memory, skill_manage
Do NOT use: skill_manage to create skills that should live in OpenCode.
```

## Hermes Tools Available (when spawned)

| Tool | Use for |
|------|---------|
| `terminal` | Run shell commands, git ops |
| `read_file` / `write_file` | File operations |
| `web_search` | Research, documentation lookup |
| `memory` | Save/recall cross-session facts (MEMORY.md) |
| `skill_manage` | Create/update skills (Hermes native) |
| `delegate_task` | Spawn further subagents (Hermes-to-Hermes) |
| `cronjob_tools` | Schedule tasks for later |
| `session_search` | Find past conversations |

## Bridging Results Back to OpenCode

When Hermes completes:
1. It returns a summary to the parent OpenCode agent
2. OpenCode specialist reports to user
3. If Hermes created a skill, OpenCode can mirror it to `~/.config/opencode/skills/`

## Configuration

### Hermes path (if not in PATH)
```bash
# Find Hermes
which hermes 2>/dev/null || ls ~/.local/bin/hermes 2>/dev/null
```

### Hermes config location
- Linux/macOS: `~/.hermes/config.yaml`
- WSL: `\\wsl$\Ubuntu\home\<user>\.hermes\config.yaml`

### External skill directories (share skills)
In Hermes config (`~/.hermes/config.yaml`):
```yaml
skills:
  external_dirs:
    - ~/.config/opencode/skills  # OpenCode skills visible to Hermes
```

In OpenCode, Hermes skills at `~/.hermes/skills/` can be mirrored to `~/.config/opencode/skills/`.

## Skill Mirroring (Bidirectional)

### OpenCode → Hermes
```bash
cp ~/.config/opencode/skills/<name>/SKILL.md ~/.hermes/skills/<name>/SKILL.md
```

### Hermes → OpenCode
```bash
cp ~/.hermes/skills/<name>/SKILL.md ~/.config/opencode/skills/<name>/SKILL.md
```

Note: Hermes skills with `metadata.hermes.*` fields will have those fields
silently ignored by OpenCode. Content is fully compatible.

## Shared Memory

Both agents can share memory via:
- **OpenCode**: `~/.config/opencode/memory/` (file-based, knowledge graph MCP)
- **Hermes**: `~/.hermes/memories/MEMORY.md` (markdown, bounded)

For cross-agent memory:
```bash
# Symlink Hermes memory to OpenCode memory dir
ln -s ~/.hermes/memories/MEMORY.md ~/.config/opencode/memory/hermes_memory.md
```

Then OpenCode can read `memory/hermes_memory.md` to see Hermes's notes.

## Session Continuity

Hermes sessions are stored in `~/.hermes/sessions/` as SQLite + FTS5.
OpenCode can query Hermes sessions for context:

```bash
sqlite3 ~/.hermes/sessions/*.db "SELECT * FROM messages WHERE content LIKE '%keyword%' LIMIT 10;"
```

### Integration Patterns

- **Skill sharing**: bidirectional mirror via `cp`, frontmatter translation (hermes `metadata.hermes.*` fields silently ignored by OpenCode)
- **Memory sync**: shared memory files via symlinks, conflict resolution by timestamp (newest wins)
- **Delegation**: OpenCode → Hermes (scheduling, messaging, cron), Hermes → OpenCode (coding, multi-file features, POA workflow)
- **CLI Setup**: `hermes` CLI installation via npm/cargo, PATH setup, key management via `~/.hermes/config.yaml`

See also: `skills/skill-learning/SKILL.md` — skill creation that works with Hermes's format.
## Do Not Use
- Configure Hermes Agent itself (use hermes-agent)
- Create OpenCode skills (use skill-learning)
- Mirror skills without Hermes CLI installed
- General integration or orchestration
