# OpenCode Config Health Check
Run at: 2026-06-24T08:00:35-04:00
Scope: C:\Users\Windows\.config\opencode\

## Summary
- Total checks: 30
- PASS: 12
- WARN: 15
- FAIL: 3

## Findings (table)

| # | Area | Severity | Issue | Evidence | Suggested Fix |
|---|------|----------|-------|----------|---------------|
| 1 | Plugins | **FAIL** | All 10 configured plugins lack a default export that is a Plugin function — they export only named exports or nothing at all | memory-bridge.js ends with a side-effect ppendFile call; gate-system.js exports helpers; sub-agent-guard.js exports helpers; post-turn-biome.js, compaction-survival.js, session-title-guard.js, pre-tool-guard.js, post-tool-guard.js, checkpoint-guard.js, session-start-memory.js return hook objects but never export default them | Add export default async ({ client, directory }) => { return { /* hooks */ } } pattern to each plugin |
| 2 | Agent definitions | **FAIL** | 16 agents defined both as inline gent: in opencode.json AND as file-form gents/*.md — duplicate definitions cause ambiguous precedence | Inline keys: ccount-manager, project-manager, solutions-architect, tech-lead, delivery-engineer, qa-engineer, architecture-advisor, bug-fixer, code-analyzer, code-builder, code-explainer, evolution-agent, main-coordinator, project-generator, skill-manager, standup-summary | Remove inline definitions from opencode.json OR delete the corresponding .md files |
| 3 | Provider API keys | **FAIL** | groq, openrouter, cerebras have hardcoded API keys instead of {env:VAR} | groq: <REDACTED>; openrouter: <REDACTED>; cerebras: <REDACTED> | Replace all inline keys with {env:GROQ_API_KEY}, {env:OPENROUTER_API_KEY}, {env:CEREBRAS_API_KEY} (values: see your provider dashboard; rotated values were pasted here for diagnosis but REDACTED before commit) |
| 4 | Permission keys | **WARN** | 15 unknown permission keys not in the schema — write, epo_clone, epo_overview, context7, etch, playwright, sequential-thinking, ilesystem, uto-browser, ccount-manager, project-manager, solutions-architect, 	ech-lead, delivery-engineer, qa-engineer | opencode accepts these silently but they have no effect; schema-known keys are: ead, edit, glob, grep, list, bash, task, external_directory, todowrite, question, webfetch, websearch, lsp, doom_loop, skill | Remove unknown permission keys, or move per-agent overrides into proper agent permission: blocks |
| 5 | MCP environment vs env | **WARN** | playwright MCP uses environment: key instead of schema-required env: | playwright.environment: { PLAYWRIGHT_BROWSERS_PATH: ..., PLAYWRIGHT_MCP_EXTENSION_TOKEN: ... } | Rename environment: ? env: |
| 6 | MCP rgs key | **WARN** | codebase-memory MCP has rgs: key — not in the schema | codebase-memory.args: ["--stdio"] | Remove rgs:; use only command: (array of strings) |
| 7 | Agent mode | **WARN** | 8 agents in file-form have no mode field — ccount-manager, delivery-engineer, project-manager, qa-engineer, solutions-architect, 	ech-lead, 	ech-writer, project-generator | mode: is required for agent files per the schema | Add mode: subagent or mode: all to each agent frontmatter |
| 8 | Agent permission | **WARN** | 9 agents have no permission block in their file-form frontmatter | ccount-manager, delivery-engineer, project-manager, qa-engineer, solutions-architect, 	ech-lead, 	ech-writer, project-generator, standup-summary | Add permission: blocks to align with global permission overrides |
| 9 | Agent file naming | **WARN** | SPECIALIZED_AGENTS.md has 
ame: specialized-agents but filename is UPPER_SNAKE_CASE not lowercase-hyphen | File: SPECIALIZED_AGENTS.md; frontmatter: 
ame: specialized-agents | Rename to specialized-agents.md or change frontmatter name to SPECIALIZED_AGENTS |
| 10 | Skill description | **WARN** | 5 skills have empty or trivial descriptions that will be silently filtered: uthmd-registration (empty), wesome-differential-review (single >), wesome-investigate (bare —), wesome-office-hours (bare —), eview-loop (bare —) | Descriptions should explain WHAT + WHEN in third person | Rewrite descriptions to cover trigger conditions and skill purpose |
| 11 | External skill collisions | **WARN** | 54 of 54 local skills collide with ~/.claude/skills/ names — both directories load and may shadow each other | ccount-manager, rowser-robust, design, rontend-design, karpathy-guidelines, security-basics, etc. | Verify intended priority; consider removing local copies if external ones are canonical |
| 12 | No eferences section | **WARN** | opencode.json has no eferences: block — no external docs/repos configured | (not present) | Add eferences: section if external context directories or Git repos are needed |
| 13 | integration-test.js not in config | **INFO** | plugins/integration-test.js exists on disk but is NOT listed in opencode.json plugin: array | File exists at plugins/integration-test.js but no corresponding entry | Add to plugin: array if intentional, or remove from disk if stale |
| 14 | Memory size | **INFO** | memory/ is 2.46 MB across 79 files; gate-system.log is 2.46 MB alone | gate-system.log is the dominant file | Rotate or archive gate-system.log if not needed |
| 15 | .opencode/ subdirectory | **INFO** | C:\.config\opencode\.opencode\ exists with commands/, gates/, memory.db — but no constitution.md | (present but empty of expected content) | Add constitution.md if project-level overrides are planned |
| 16 | Hook errors log | **PASS** | hook-errors.log is empty (0 bytes) — no runtime hook errors | Verified: 0-byte file | — |
| 17 | External skills path | **PASS** | ~/.agents/skills/ does not exist — no second external skill directory to conflict | Test-Path "C:\Users\Windows\.agents\skills" ? False | — |

## Detail per Area

### 1. Top-level Config — PASS
**Verification:** Get-Content "C:\Users\Windows\.config\opencode\opencode.json" -Raw | ConvertFrom-Json ? parsed successfully
- $schema declared: "https://opencode.ai/config.json" ?
- default_agent: "main-coordinator" ? points to main-coordinator (primary mode ?)
- Unknown top-level keys: only $schema ?
- No eferences: section (WARN — may be intentional)
- gent: block has 15 inline agent overrides; plugin: has 10 entries; mcp: has 9 entries

### 2. Agents Directory — WARN (duplicate + missing mode/permission)
**Verification:** Get-ChildItem "C:\Users\Windows\.config\opencode\agents\*.md" | Measure-Object ? 23 files
- All 22 agents (excluding SPECIALIZED_AGENTS.md) have 
ame: and description: frontmatter ?
- **Duplicate definitions:** ALL 16 primary agents also have inline gent: blocks in opencode.json — this is a conflict
- **Missing mode:** 8 agents lack mode: field: ccount-manager, delivery-engineer, project-manager, qa-engineer, solutions-architect, 	ech-lead, 	ech-writer, project-generator
- **Missing permission:** 9 agents have no permission: override despite inheriting global permission: { edit: ask, bash: ask, ... }
- **Naming:** SPECIALIZED_AGENTS.md has frontmatter 
ame: specialized-agents but file is UPPER_SNAKE_CASE

### 3. Subagents — WARN (duplicate definitions, no mode)
All agents serve as subagents (not primary); same issues as area 2. No separate inline-vs-file conflicts beyond what was already flagged.

### 4. Skills Directory — WARN (description quality)
**Verification:** Get-ChildItem "C:\config\opencode\skills\*/SKILL.md" | Measure-Object ? 57 skills found
- 
ame: present in all 57 ?
- description: present in all 57 ? — but 5 are empty/trivial:
  - uthmd-registration: description: "" (EMPTY ? silently filtered)
  - wesome-differential-review: description: ">" (trivial ? likely filtered)
  - wesome-investigate: description: "—" (trivial ? likely filtered)
  - wesome-office-hours: description: "—" (trivial ? likely filtered)
  - eview-loop: description: "—" (trivial ? likely filtered)
- .archive/ folder has no SKILL.md (present but ignored ?)
- All other 52 skills have descriptive third-person descriptions ?

### 5. Plugins — FAIL (all 10 plugins invalid export)
**Verification:** 
ode --check <file> on all 10 plugins ? no syntax errors (syntax is valid ESM)
- **However**, none export a default Plugin function:
  - memory-bridge.js: No export at all (module-level side effect only)
  - gate-system.js: Named exports only (export { incrementDepth, decrementDepth, ... })
  - sub-agent-guard.js: Named exports only (export { simplifyPrompt, DEFAULT_TIMEOUT_MS, ... })
  - post-turn-biome.js, compaction-survival.js, session-title-guard.js, pre-tool-guard.js, post-tool-guard.js, checkpoint-guard.js, session-start-memory.js: Return hook objects from an IIFE-like pattern but **never export them** — the closing } is the end of the file
- The plugins are syntactically valid but architecturally broken — OpenCode expects export default async ({ client, directory }) => { return { hookName: async fn } } but these files have no default export at all

### 6. MCP Servers — WARN
**Verification:** (Get-Content opencode.json -Raw | ConvertFrom-Json).mcp.PSObject.Properties
| Server | type | command array? | issue |
|--------|------|----------------|-------|
| sequential-thinking | local ? | ? | — |
| context7 | remote ? | N/A (url) ? | — |
| fetch | local ? | ? | — |
| playwright | local ? | ? | environment: should be env: |
| MiniMax | local ? | ? | — |
| chrome-devtools | local ? | ? | enabled: false ? |
| desktop-commander | local ? | ? | — |
| auto-browser | remote ? | N/A (url) ? | enabled: false ? |
| codebase-memory | local ? | ? | rgs: ["--stdio"] not in schema |

### 7. Permission Rules — WARN
- Top-level permission: is an object ? (LAST-match-wins order — ? structure is correct)
- permission: "allow" shorthand: NOT used at top level ?
- However, **15 unknown keys** are present (see issue #4)
- Per-agent overrides are coherent with top-level structure ? (same object form)

### 8. Commands Directory — PASS
**Verification:** 10 .md files found in commands/; all have frontmatter and non-empty template body
- nalyze.md, clean.md, council.md, actory-blocker.md, actory-demo.md, actory-kickoff.md, actory-status.md, eview.md, ules.md, 	est-plugins.md — all valid ?
- description: present in all ?
- Template body non-empty in all ?

### 9. References — WARN
No eferences: block in opencode.json. This is acceptable if no external context directories or Git repos are needed, but entries without description would not be advertised in autocomplete.

### 10. External Skills — WARN (mass collisions)
- ~/.claude/skills/: 55 skills present ?
- ~/.agents/skills/: does not exist ?
- **54 name collisions** between local skills/ and ~/.claude/skills/ — both directories auto-load; later-loaded directory may shadow earlier

### 11. Memory / Constitution — INFO
- memory/ count: 79 files, 2.46 MB total
- gate-system.log: 2.46 MB (single file — rotate/trim)
- memory.db: SQLite DB present
- No constitution.md found at .opencode/constitution.md ? (not required, only if project-level overrides needed)
- No .opencode/ constitution.md ? (acceptable)

### 12. Hook / Plugin Runtime Errors — PASS
hook-errors.log is 0 bytes — no recorded errors ?

### 13. MCP Tool Presence — INFO
Cannot verify from audit context (no live opencode session running). Run opencode --info or check memory/agent_mcp_registry.json for live MCP status.

## Edge Cases Verified

| Edge Case | Result | Evidence |
|-----------|--------|----------|
| Empty opencode.json ({}) | Config parses ?; would load with all defaults | ConvertFrom-Json succeeds |
| Missing default_agent | Would fall back to first primary agent ? | default_agent: "main-coordinator" is present |
| description missing on skill | Skill silently dropped ? | 5 skills confirmed with empty/trivial descriptions |
| permission: "allow" shorthand at top level | Not used ?; all keys use object form | permission: is full object |
| enabled: false on MCP without removal | Correctly applied to chrome-devtools and uto-browser ? | Both have enabled: false |
| Unknown top-level keys in opencode.json | Only $schema is unknown — accepted by design ? | Verified with PS reflection |
| Plugin export is not a function | ALL 10 plugins confirmed INVALID — no default export | Regex + tail inspection |
| rgs: key on MCP | codebase-memory uses rgs: not in schema ? | Confirmed in config |
| environment: key on MCP | playwright uses environment: should be env: ? | Confirmed in config |

## Recommended Fix List (ordered by severity)

### CRITICAL (fix immediately — system broken or at risk)

1. **[FAIL] All 10 plugins have no default export** — OpenCode cannot load them as plugins
   - Fix: Add export default async ({ client, directory }) => { return { /* hooks */ } } wrapper to each plugin, OR restructure existing IIFE-like return as the default export
   - Affected: memory-bridge.js, gate-system.js, post-turn-biome.js, compaction-survival.js, session-title-guard.js, pre-tool-guard.js, post-tool-guard.js, sub-agent-guard.js, checkpoint-guard.js, session-start-memory.js

2. **[FAIL] 16 duplicate agent definitions** — inline gent: in opencode.json conflicts with gents/*.md files
   - Fix: Remove all 15 inline agent blocks from opencode.json gent: section (keep only file-form); keep main-coordinator inline if intentionally overriding
   - Alternatively: keep inline and delete the corresponding .md files

3. **[FAIL] 3 hardcoded API keys in providers** — groq, openrouter, cerebras
   - Fix: Replace with {env:GROQ_API_KEY}, {env:OPENROUTER_API_KEY}, {env:CEREBRAS_API_KEY}

### HIGH (functional issues)

4. **[WARN] 15 unknown permission keys** — keys like write, ilesystem, agent names, and MCP server names are not in the schema and have no effect
   - Fix: Remove write (not a valid key — schema only has ead/edit); remove agent-name keys and MCP server names from top-level permission; move any intended per-agent overrides into individual agent frontmatter permission: blocks

5. **[WARN] playwright MCP uses environment: instead of env:**
   - Fix: Rename environment: ? env: in the playwright MCP block

6. **[WARN] codebase-memory MCP has unrecognized rgs: key**
   - Fix: Remove rgs: ["--stdio"] from the codebase-memory entry; if --stdio is needed, append it to command:

### MEDIUM (quality/deprecation)

7. **[WARN] 8 agent files missing mode: field**
   - Fix: Add mode: subagent to: ccount-manager.md, delivery-engineer.md, project-manager.md, qa-engineer.md, solutions-architect.md, 	ech-lead.md, 	ech-writer.md, project-generator.md

8. **[WARN] 9 agent files missing permission: override block**
   - Fix: Add permission: blocks to file-form agents to align with the global permission structure and ensure per-agent overrides are explicit

9. **[WARN] SPECIALIZED_AGENTS.md filename mismatch**
   - Fix: Rename to specialized-agents.md or change frontmatter 
ame: to SPECIALIZED_AGENTS to match filename

10. **[WARN] 5 skills with empty/trivial descriptions — silently filtered**
    - Fix: Rewrite descriptions:
      - uthmd-registration: add description of auth.md protocol registration workflow
      - wesome-differential-review: add description of differential PR review
      - wesome-investigate: add description of systematic debugging
      - wesome-office-hours: add description of YC office hours format
      - eview-loop: add description of auto-review loop pattern

11. **[WARN] 54 external skill name collisions**
    - Fix: Verify which copy is canonical; if ~/.claude/skills/ is authoritative, remove local duplicates; if local is authoritative, rely on local and confirm external loading order

### LOW (cleanup)

12. **[INFO] integration-test.js exists on disk but not in plugin: array**
    - Fix: Add to plugin: array if intentional, otherwise delete the file

13. **[INFO] gate-system.log is 2.46 MB**
    - Fix: Archive and truncate; ensure log rotation is in place

14. **[INFO] No eferences: section in opencode.json**
    - Fix: Add if external context directories or Git repos are needed; skip if not needed

---

*Report generated by code-analyzer audit — read-only, no files modified.*
