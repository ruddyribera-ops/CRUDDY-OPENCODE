# Risks & Assumptions — OpenCode Config Health Fix Sprint 001

---

## Known Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Plugin rewrite breaks working code** — if we add `export default` wrappers to plugins that already work via named exports, we could introduce new bugs | MEDIUM | HIGH | **Verify FIRST (Area 0)**: run OpenCode with existing plugins and check `hook-errors.log`. Only touch plugins if they actually fail to load. |
| **Agent dedup loses inline overrides** — removing inline `agent:` blocks may lose settings that were intentionally different from the .md form | MEDIUM | MEDIUM | **Diff before delete**: compare each inline agent block against its .md counterpart. Keep inline ONLY if it has fields not in .md that you want to preserve. Snapshot first. |
| **Silent API failure from unset env vars** — `{env:GROQ_API_KEY}` with an unset env var resolves to empty string `""`, causing silent API failures | HIGH | HIGH | **Document the required env vars clearly**. Add a startup self-check in the pack: on first restart, run a test API call or warn if `GROQ_API_KEY` is empty. |
| **opencode.json JSON becomes invalid** — a single syntax error in opencode.json (missing comma, unquoted key, etc.) bricks OpenCode startup | MEDIUM | CRITICAL | **Snapshot before every edit to opencode.json**. Keep backup path: `planning/sprints/sprint-001/backups/opencode.json.pre-fix`. Have escape-hatch ready: `OPENCODE_DISABLE_PROJECT_CONFIG=1` or `OPENCODE_CONFIG=/path/to/backup.json`. |
| **Skill collision behavior change** — removing a local skill that shadowed an external one could change which skill is loaded | LOW | MEDIUM | **List both versions side-by-side before removing either**. Decision per-skill is documented in skill-collision-report.md. |
| **Snapshot not taken before edits** — if implementer skips the snapshot step, rollback is impossible | MEDIUM | HIGH | Snapshot step is step 0 in the blueprint. It is MANDATORY. No edit allowed until snapshot exists. |
| **codebase-memory MCP breaks after `args:` removal** — if the MCP server truly requires `--stdio` and it is not in `command:`, the server fails to start | LOW | MEDIUM | Append `--stdio` to the `command:` array (string, not separate key). This is the schema-correct way. Verify: after edit, `opencode --info` shows codebase-memory as connected. |
| **Wrong `mode:` value** — adding `mode: subagent` to agents that should be `mode: all` changes dispatch behavior | LOW | MEDIUM | Check existing agents that DO have `mode:` to confirm the correct value. Most of these agents should be `subagent` (they are specialists called by main-coordinator). `project-manager` and `main-coordinator` may differ. |
| **Permission cleanup removes intentional overrides** — some agent names in top-level permission may have been intentional (even if not schema-valid) | LOW | LOW | These keys had NO EFFECT per schema — they were silently ignored. Removing them cannot break anything that was working. |
| **Area 0 runtime verify inconclusive** — if OpenCode has no `--info` flag or no easy way to check plugin loading, we cannot confirm named exports work | LOW | MEDIUM | Fall back to: add `export default` wrappers to all 10 plugins (Area 1) even if it may be unnecessary. Safer than leaving potential non-loading plugins. |

---

## Assumptions Made

1. **OpenCode Go plugin loader supports named exports** — research says `export const PluginName = async (...) => ({hooks})` satisfies the Plugin type. We assume this is true until proven otherwise.
2. **Env var substitution happens at load time** — `{env:VAR}` is replaced with the shell env value when OpenCode parses the config, not at first API call. If this is wrong, the entire env var approach is invalid.
3. **agents/*.md wins over inline `agent:`** — per official docs, file-form has higher precedence for conflicts. We assume this is implemented correctly in OpenCode Go.
4. **Snapshot + rollback works** — we assume copying `opencode.json` to a backup path and restoring it actually resets the config state. On Windows, this should work.
5. **No live OpenCode session during fixes** — we assume the user will close all OpenCode instances before applying fixes. A running session may cache the old config.
6. **Gate-system.log rotation is safe** — the log is written by plugins; rotating it to a new file while plugins are running may lose the write handle briefly. We assume this is safe (new log is created, old one archived).
7. **`hook-errors.log` path is correct** — confirmed as `C:\Users\Windows\.config\opencode\hook-errors.log` in the health check.
8. **skill-learning and hermes-agent references are the only consumers of customize-opencode** — no other file references it. Creating the skill resolves both broken references.
9. **The 5 skills with empty descriptions were intentionally empty** — they were created as stubs. Rewriting them with real descriptions is safe.
10. **integration-test.js is not intentionally excluded** — it was in the plugin array originally (the audit says it exists on disk but is NOT in the array). Either it was accidentally removed or was never intended to be there. We treat it as an orphan.

---

## Open Questions (for Ruddy)

- [ ] **main-coordinator inline override**: The inline `agent.main-coordinator` block in opencode.json has `steps: 250`. Does the `agents/main-coordinator.md` have a different `steps` value? If so, do you want to keep the inline override or trust the .md form?
- [ ] **integration-test.js**: Should this plugin be added back to the plugin array, or deleted from disk?
- [ ] **references: section**: Do you use external context directories or Git repos that should be listed in `references:`? If not, we'll mark it as intentionally absent.
- [ ] **Skill collisions (54)**: Should we prefer local skills or external ~/.claude/skills/ for the collisions? Or keep both?
- [ ] **API key dashboard rotation**: Have you rotated the exposed API keys at groq/openrouter/cerebras dashboards? (This sprint fixes the config syntax only — the exposed keys still need rotation as a separate security step.)

---

## Escape Hatches (if opencode.json breaks)

```powershell
# Escape hatch 1: Disable project config loading
$env:OPENCODE_DISABLE_PROJECT_CONFIG = "1"
# Then start opencode to get a working shell, fix the JSON, remove the env var

# Escape hatch 2: Point to backup config
$env:OPENCODE_CONFIG = "C:\Users\Windows\.config\opencode\planning\sprints\sprint-001\backups\opencode.json.pre-fix"
# Then start opencode with backup, fix the original

# Escape hatch 3: Restore from backup manually
Copy-Item "C:\Users\Windows\.config\opencode\planning\sprints\sprint-001\backups\opencode.json.pre-fix"
          "C:\Users\Windows\.config\opencode\opencode.json" -Force
```

---

## Backup Inventory

| File | Backup Path |
|------|------------|
| `opencode.json` (pre-fix) | `planning/sprints/sprint-001/backups/opencode.json.pre-fix` |
| `agents/` (pre-fix) | `planning/sprints/sprint-001/backups/agents.pre-fix/` |
| `gate-system.log` (archived) | `memory/gate-system.{timestamp}.log` |

---

*End of risks.md*