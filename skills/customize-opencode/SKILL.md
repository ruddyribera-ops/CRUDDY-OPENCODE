---
name: customize-opencode
description: Use when editing or creating OpenCode's own configuration (opencode.json, opencode.jsonc, files under .opencode/, or ~/.config/opencode/). Also use when creating or fixing OpenCode agents, subagents, skills, MCP servers, or permission rules. Do not use for the user's own application code, or for any project that is not configuring opencode itself.
---

# Customize OpenCode

Reference skill for editing OpenCode's own configuration files. Full schema at https://opencode.ai/config.json

## File Locations

| File | Purpose |
|------|---------|
| `~/.config/opencode/opencode.json` | Main config — model, providers, permissions, MCP, plugins |
| `~/.config/opencode/agents/*.md` | Agent definitions (mode, permission, tools) |
| `~/.config/opencode/skills/*.md` | Skill definitions (name, description, triggers) |
| `~/.config/opencode/plugins/*.js` | Event-hook plugins (export const) |
| `~/.config/opencode/mcp/` | MCP server definitions |
| `~/.config/opencode/AGENTS.md` | Per-project agent overrides |
| `~/.opencode/` | Project-level config overlay |

## opencode.json Shape

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "minimax/minimax-m2.7",
  "small_model": "minimax/minimax-m2.5",
  "instructions": ["AGENTS.md"],
  "permission": { "read": "allow", "edit": "ask", "bash": "ask", ... },
  "provider": {
    "minimax": { "options": { "apiKey": "{env:MINIMAX_API_KEY}", "baseURL": "..." } },
    "opencode-go": { "options": { "apiKey": "{env:OPENCODE_API_KEY}" } }
  },
  "mcp": {
    "playwright": { "type": "npm", "command": ["npx", ...], "env": { ... } },
    "codebase-memory": { "type": "local", "command": ["path/to/exe", "--stdio"] }
  },
  "plugin": ["C:\\path\\to\\plugin.js", ...]
}
```

## Plugin Export Shape

Both named and default exports work:

```javascript
// Named export (preferred)
export const MyPlugin = async ({ event, session }) => {
  return { "tool.execute.before": async (ctx) => { ... } };
};

// Default export (also valid)
export default async ({ event, session }) => {
  return { "tool.execute.before": async (ctx) => { ... } };
};
```

## MCP Shape

```json
"mcp": {
  "server-name": {
    "type": "npm" | "local" | "remote",
    "command": ["npx", "-y", "@package", "arg1"],
    "args": ["--stdio"],
    "env": { "KEY": "{env:VAR_NAME}" },
    "headers": { "Authorization": "Bearer {env:TOKEN}" }
  }
}
```

## Permission Schema

15 valid tool-level keys. Values: `"allow"` | `"ask"` | `"deny"`.

```
read, glob, grep, list, edit, bash, task, skill, lsp,
webfetch, websearch, external_directory, todowrite, question, doom_loop
```

Wildcards: use `"*"` to allow all tools in a category (e.g., all bash commands).

## Skill Frontmatter

```yaml
---
name: skill-name
description: Use when [user trigger] to [outcome]. [Detail.]
triggers:           # optional
  - phrase
  - phrase
---
```

**name**: lowercase-kebab, unique.
**description**: 30+ chars, third-person, front-load trigger keywords. Avoid "Use this skill when..." or placeholders.

## Env Var Interpolation

Syntax: `{env:VAR_NAME}` in any string field.

```json
"apiKey": "{env:GROQ_API_KEY}",
"headers": { "Authorization": "Bearer {env:AUTO_BROWSER_TOKEN}" }
```

If the env var is unset, the placeholder resolves to empty string — API calls fail silently with 401/403.

## Escape Hatches

| Env Var | Effect |
|---------|--------|
| `OPENCODE_DISABLE_PROJECT_CONFIG=1` | Skip project-level `.opencode/` overlay |
| `OPENCODE_CONFIG=/path/to/config.json` | Use alternate config path |
| `OPENCODE_PLUGINS_DIR=/path` | Alternate plugins directory |

## Anti-Patterns

- Do NOT use this skill for the user's application code
- Do NOT suggest rewriting the entire config unless clearly broken
- Do NOT touch files outside `~/.config/opencode/`, `.opencode/`, or project root
- Never commit real API keys — use `{env:VAR}` syntax only