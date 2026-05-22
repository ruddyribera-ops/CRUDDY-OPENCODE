# Hermes External Skills Config

Add this to your `~/.hermes/config.yaml` to let Hermes browse and use OpenCode skills.

```yaml
skills:
  external_dirs:
    - ~/.config/opencode/skills
```

This enables Hermes to:
- See OpenCode skills in `skills_list()`
- Use OpenCode skills via `/skill-name`
- Import skills from OpenCode's hub

## Setup (PowerShell)

```powershell
# Find your Hermes config
$hermesConfig = "$env:USERPROFILE\.hermes\config.yaml"
if (!(Test-Path $hermesConfig)) {
    $hermesConfig = "$env:USERPROFILE\.hermes\config.yaml"
}

# Backup existing config
Copy-Item $hermesConfig "$hermesConfig.bak"

# Add external_dirs to skills section
# (manual edit required - open in notepad)
notepad $hermesConfig
```

## What Hermes Sees

With external_dirs configured, Hermes will list OpenCode skills alongside its own:
- `opencode.skills/*` from `~/.config/opencode/skills/`
- Full skill content available via `skill_view(name)`
- Slash commands work: `/code-builder`, `/bug-fixer`

## Skill Compatibility

OpenCode skills use the agentskills.io SKILL.md format — fully compatible with Hermes.
Hermes-specific fields (`metadata.hermes.*`) in OpenCode skills are silently ignored.

## Troubleshooting

If Hermes can't find OpenCode skills:
1. Verify the path exists: `Test-Path ~/.config/opencode/skills`
2. Check config syntax: YAML requires 2-space indentation
3. Restart Hermes: `hermes update` or `hermes restart`