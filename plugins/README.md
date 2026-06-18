# Gate System

Self-evolving enforcement layer for OpenCode v1.15.13.

## What it does

1. **Counts tasks** (via `command.execute.before` hook) on every bash command
2. **Triggers retro-analyze** every 10 tasks (auto-writes gene candidates to DNA.yaml)
3. **Validates DNA.yaml** on every read/edit (via `tool.execute.before` hook) using zod
4. **Auto-evolves** the system by surfacing blocked patterns as new genes

## Files

| File | Purpose |
|------|---------|
| `plugins/gate-system.js` | Main plugin (hooks + zod + counter + retro trigger) |
| `plugins/gate-system.test.js` | 24-test Pester-equivalent suite (uses `node --test`) |
| `plugins/package.json` | Local deps: `js-yaml`, `zod` |
| `plugins/node_modules/` | Installed deps (gitignored in real project) |
| `scripts/gate/retro-analyze.ps1` | PowerShell script: pattern detection + gene write |
| `scripts/gate/gate-check.ps1` | PowerShell script: proof enforcer (4 gates) |
| `scripts/gate/gene-approve.ps1` | PowerShell script: list/approve/reject auto-genes |
| `scripts/gate/task-init.ps1` | PowerShell script: creates task state |
| `.pre-commit-config.yaml` | Git hooks: DNA schema + JS syntax validation |
| `gates/<task_id>/state.yaml` | Per-task state (written by gate-check.ps1) |

## How it works

```
User runs any bash command in OpenCode
        |
        v
[command.execute.before hook] (gate-system.js)
        |
        +- count++
        +- if count % 10 == 0: spawn retro-analyze.ps1 -WriteGenes
        |
        v
User edits DNA.yaml
        |
        v
[tool.execute.before hook] (gate-system.js)
        |
        +- zod.validate(DNA.yaml)
        +- if invalid: warn to console (don't block, user might be fixing)
        |
        v
User runs git commit
        |
        v
[pre-commit hook] (pre-commit-hooks)
        |
        +- check-yaml on DNA.yaml
        +- node --test runs zod schema validation
        +- node --check on all plugin .js files
```

## Running tests

```bash
cd ~/.config/opencode/plugins
npm install      # first time
node --test gate-system.test.js
```

Expected output: 24/24 passing.

## Triggering retro-analyze manually

```bash
# Run with dry-run (preview only, no writes)
powershell -File ~/.config/opencode/scripts/gate/retro-analyze.ps1 -TaskCount 10 -DryRun

# Run with writes (auto-creates genes)
powershell -File ~/.config/opencode/scripts/gate/retro-analyze.ps1 -TaskCount 10 -WriteGenes

# Then review and approve
powershell -File ~/.config/opencode/scripts/gate/gene-approve.ps1 -List -Pending
powershell -File ~/.config/opencode/scripts/gate/gene-approve.ps1 -Approve CODE-AUTO-001
```

## Exit codes

- `0` = clean, no patterns
- `2` = genes written, evolution-agent should review

## Why this architecture

- **No custom YAML parser** — uses `js-yaml` (164M downloads, mature)
- **No custom validator** — uses `zod` (industry standard, OpenCode's own dep)
- **No custom test framework** — uses Node 24's built-in `node --test`
- **Atomic writes** — temp + rename (no partial writes)
- **Lockfile protocol** — `wx` exclusive create (cross-process safety)
- **Caching** — mtime-based, auto-invalidates on file change
- **Pre-commit** — git-level safety net, runs all tests

## The closed loop

1. Agent runs 10 bash commands
2. Plugin auto-spawns retro-analyze
3. retro-analyze detects patterns, writes gene candidates
4. Evolution-agent reviews and approves
5. New gene is now a permanent rule
6. System gets smarter without human action

## Troubleshooting

- **Plugin not loading**: Check `opencode.json` has `gate-system.js` in `plugin` array
- **Counter stuck**: Delete `gates/.task-counter.json`
- **DNA.yaml validation errors**: Run `node --test gate-system.test.js` to see details
- **retro-analyze silent failure**: Check `gates/retro-analyze.log` (if logging added)
