# Architect Pack — Sprint 001
## Pack: opencode-config-health-fix v1.0
## Sprint: 001

---

## 1. REQUIREMENTS — What we're fixing and why

### Business Goal
Restore the OpenCode global config at `C:\Users\Windows\.config\opencode\` to a state where: (a) no findings are FAIL, (b) all WARNs are either fixed or documented-as-intentional, and (c) the system starts without errors and plugins load correctly.

### Audit Source
- `C:\Users\Windows\.config\opencode\health-check-report.md` (run 2026-06-24)
- Research corrections applied from web research (opencode.ai/docs, config schema)

### Research Corrections to the Audit

| Audit Finding | Original Verdict | Research Correction | Impact |
|---|---|---|---|
| All 10 plugins lack `export default` | FAIL | Named exports (`export const X = async (...) => ({...})`) ALSO satisfy the Plugin type. The 10 plugins DO have named exports — but whether OpenCode Go's loader uses `export default` specifically vs. scans for named exports is UNKNOWN. Must verify at runtime before touching working code. | Plugin FAIL is a VERIFY_FIRST — not a blind rewrite |
| 16 agents in both inline + .md | FAIL | Official docs: "Configuration files are merged, not replaced." `agents/<name>.md` wins for conflicting fields. Dedup is a CLEANUP, not a bug fix. | Agent duplicate is non-breaking but messy |
| Hardcoded API keys (groq, openrouter, cerebras) | FAIL | `{env:VAR_NAME}` syntax is CORRECT per schema. Unset env var → empty string (silent failure). User MUST set the env vars. | Env var fix is correct syntax; risk is empty-value silent failure |
| 15 unknown permission keys | WARN | `write` is not a valid key (schema: `edit`); `filesystem` is not valid; agent names and MCP names as top-level permission keys are not valid | Remove invalid keys; use `permission.task` glob patterns instead |
| 54 local skills collide with ~/.claude/skills/ | WARN | Both directories auto-load; no silent shadowing. Both descriptions surface to the model. | Collision is NOT a shadowing bug; cleanup is optional |
| customize-opencode skill MISSING | META | References in `skill-learning` and `hermes-agent` point to a non-existent file. Must either create it or remove references. | Create the skill with correct content |

### FAIL Findings (3 — must fix)

| # | Finding | Verification Required |
|---|---|---|
| F1 | All 10 plugins lack `export default` — OpenCode Go may not load them | **RUNTIME VERIFY FIRST**: Does OpenCode load these plugins as-is? If yes, named exports are sufficient and no change needed. If no, add `export default` wrapper. |
| F2 | 16 agents defined in BOTH `opencode.json` inline AND `agents/*.md` | Per research: `agents/*.md` wins for conflicts. Dedup the inline `agent:` blocks from `opencode.json`. |
| F3 | 3 hardcoded API keys in providers (groq, openrouter, cerebras) | Replace with `{env:GROQ_API_KEY}`, `{env:OPENROUTER_API_KEY}`, `{env:CEREBRAS_API_KEY}`. User must set these env vars. |

### WARN Findings (15 — fix unless documented-as-intentional)

| # | Finding | Fix Required |
|---|---|---|
| W1 | `write` is not a valid permission key | Remove from top-level `permission:`. `edit` is the correct key. |
| W2 | `filesystem` is not a valid permission key | Remove from top-level `permission:`. |
| W3 | Agent names as top-level permission keys (account-manager, etc.) | Remove. Use per-agent `permission:` blocks with glob patterns instead. |
| W4 | MCP names as top-level permission keys (context7, fetch, playwright, etc.) | Remove. These MCP names are not tool names in the schema. |
| W5 | `playwright` MCP uses `environment:` instead of `env:` | Rename key to `env:`. |
| W6 | `codebase-memory` MCP has `args:` key (not in schema) | Remove `args:`. If `--stdio` is needed, append to `command:`. |
| W7 | 8 agent files missing `mode:` field | Add `mode: subagent` or `mode: all` to frontmatter. |
| W8 | 9 agent files missing `permission:` block | Add `permission:` blocks aligned with global structure. |
| W9 | `SPECIALIZED_AGENTS.md` filename UPPER_SNAKE_CASE vs frontmatter `name: specialized-agents` | Rename file to `specialized-agents.md` (lowercase) to match frontmatter. |
| W10 | 5 skills with empty/trivial descriptions (silently filtered) | Rewrite descriptions to explain WHAT + WHEN in third person. |
| W11 | 54 local skills collide with ~/.claude/skills/ names | Document both are loaded; no silent shadowing. Decide which is canonical per-skill. |
| W12 | No `references:` section in opencode.json | Add if external context dirs/repos needed; otherwise document as intentional. |
| W13 | `integration-test.js` exists on disk but not in plugin array | Add to `plugin:` array if intentional; otherwise delete from disk. |
| W14 | `gate-system.log` is 2.46 MB | Archive and truncate. Set rotation. |
| W15 | `repo_clone` and `repo_overview` not in schema | Remove from top-level `permission:`. |

### Out of Scope (explicit)
- **API key rotation at provider dashboards**: User must do this manually. We fix the config syntax only.
- **External ~/.claude/skills/ modifications**: We do not modify the external skills directory.
- **Installing missing npm/npx packages**: The MCP servers (playwright, context7, etc.) require pre-installed tools. We assume they are present.

### Dependencies
1. **Before ANY edits**: Snapshot `opencode.json` to `planning/sprints/sprint-001/backups/opencode.json.pre-fix`
2. **Env vars setup**: User must set `GROQ_API_KEY`, `OPENROUTER_API_KEY`, `CEREBRAS_API_KEY`, `MINIMAX_API_KEY`, `OPENCODE_API_KEY`, `PLAYWRIGHT_MCP_TOKEN`, `AUTO_BROWSER_TOKEN`, `OPERATOR_ID`, `OPERATOR_NAME` in their shell environment before restarting OpenCode.
3. **Runtime verification**: After each area fix, restart OpenCode and verify no startup errors.
4. **Plugin runtime check**: Before touching any plugin, run `opencode --info` or trigger a session to see if plugins load from the named exports.

### Phasing Decision: One Sprint (Fix-and-Verify Per Area)

**Why one sprint, not multiple:**
- All findings are in the same config file ecosystem; they don't block each other.
- The risk of multi-sprint context switching outweighs the effort savings.
- The only true "blocking" unknown is whether named-export plugins work — and that one verification resolves the entire plugin FAIL question.

**Per-area ordering (constraint: FAILs first):**

```
Area 0: Snapshot + Plugin Runtime Verify  (determines if area 1 is needed)
Area 1: Agent dedup (opencode.json inline removal)        → FAIL-2
Area 2: Provider API key → env var replacement             → FAIL-3
Area 3: Permissions cleanup (remove invalid keys)          → WARN-1,2,3,4,15
Area 4: MCP fixes (environment:→env:, remove args:)         → WARN-5,6
Area 5: Agent frontmatter (add mode:, permission:)          → WARN-7,8
Area 6: Skill descriptions (rewrite 5 empty/trivial)       → WARN-10
Area 7: File rename (SPECIALIZED_AGENTS.md)                 → WARN-9
Area 8: Skill collision documentation (list, decide)        → WARN-11
Area 9: Missing customize-opencode skill (create)          → META-1
Area 10: integration-test.js decision                       → W13
Area 11: Log rotation (gate-system.log)                    → W14
Area 12: references: section (add or document intentional)  → W12
```

Parallelizable: Areas 3+4+5 can run in parallel (different files). Areas 6+7+8+10+11+12 are independent and can run in parallel. Areas 1+2 must run sequentially (both edit opencode.json).

---

*End of requirements.md*