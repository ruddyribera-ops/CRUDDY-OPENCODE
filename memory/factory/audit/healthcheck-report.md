# OpenCode Config Healthcheck — 2026-06-26

**Auditor:** code-analyzer (structural + consistency lens)  
**Parallel audit:** expert-tester (adversarial lens) — running concurrently

---

## Summary
- **CRITICAL:** 1
- **HIGH:** 4
- **MEDIUM:** 5
- **LOW:** 4

---

## Inventory

| Category | Count | Notes |
|----------|-------|-------|
| Agents | 25 .md + 1 SPECIALIZED_AGENTS.md reference doc | 24 real agents + 1 aspirational doc |
| Skills | 31 skill directories + 3 root .md files | All referenced skills verified present |
| Commands | 10 | All have .md files |
| Scripts | 110+ | Mix of PS1, JS, TS, Python, MJS |
| Plugins | 12 .js files (excluding 
ode_modules, package.json) | _shared.js is correctly non-exporting utility |
| Memory files | 60+ | Log files, YAML configs, JSONL sessions |
| Rules | 24 rule files across ules/ and ules/agent_rules/ | |

**Orphan analysis:** No orphaned agent files found. All 24 agent .md files match entries in AGENTS.md.  
**Missing references:** SPECIALIZED_AGENTS.md is referenced only in the filename listing — it is not referenced from AGENTS.md or any other config, confirming it is a true orphan reference doc.

---

## CRITICAL

### C-1: designer.yaml references non-existent skills
- **File:** gents/designer.yaml:18-20
- **Problem:** skills_used lists design, ui-design, and rontend-design, but rontend-design and design skills do not exist in skills/ directory.
- **Why it matters:** When @designer is dispatched, it will fail to load non-existent skills, breaking the designer's workflow at runtime.
- **Fix:** Remove design and rontend-design from skills_used, keeping only ui-design which exists.

---

## HIGH

### H-1: Duplicate routing entry for "Write/structure docs"
- **File:** AGENTS.md:53,66
- **Problem:** The Intent → Agent routing table has two identical rows for Write/structure docs → tech-writer with the same trigger words (document, doc, README, ...).
- **Why it matters:** Redundant table entry increases routing table size and suggests copy-paste error; could cause confusion during maintenance.
- **Fix:** Remove the duplicate row at line 66.

### H-2: main-coordinator.md is 1,358 lines — exceeds recommended agent prompt size
- **File:** gents/main-coordinator.md
- **Problem:** Single agent file at 1,358 lines; AGENTS.md itself is only 205 lines. This is 6.6× larger than the next largest agent and suggests the coordinator file may contain bloated or duplicated content.
- **Why it matters:** Large prompts consume more context window, increase token cost per session, and are harder to maintain. The coordinator is the most frequently invoked agent.
- **Fix:** Audit main-coordinator.md for redundant boilerplate, split into functional sections (routing table, handoff rules, convergence rules, auto-handoff patterns), and extract static reference content into linked documents.

### H-3: code-builder.md is 891 lines — second-largest agent file
- **File:** gents/code-builder.md
- **Problem:** At 891 lines, this agent prompt is significantly larger than most others and well beyond the median.
- **Why it matters:** High token burn rate for every code-builder invocation; bloated prompts degrade performance on long coding sessions.
- **Fix:** Audit code-builder.md for repeated boilerplate across agent files; extract static reference content (e.g., anti-patterns lists, conventions) into linked rule files.

### H-4: designer.yaml has duplicate model_tier field
- **File:** gents/designer.yaml:4,6
- **Problem:** model_tier: 2 appears twice in the YAML frontmatter.
- **Why it matters:** YAML parsers will use the second value silently; this could cause unexpected model tier selection if the field is consumed programmatically.
- **Fix:** Remove the duplicate model_tier: 2 at line 4 (keep line 6).

---

## MEDIUM

### M-1: gent_mcp_registry.json defines irecrawl-mcp but opencode.json does not list it
- **File:** memory/agent_mcp_registry.json vs opencode.json
- **Problem:** The MCP registry records a irecrawl-mcp server as active, but opencode.json's mcpServers section does not include it.
- **Why it matters:** The registry may be stale, or the server config is missing from the primary config — either way, the discrepancy means the MCP server may not be properly configured for use.
- **Fix:** Add irecrawl-mcp to opencode.json's mcpServers or confirm it's configured elsewhere (e.g., via environment or CLI flag).

### M-2: hook-errors.log is 5 bytes — appears empty or near-empty
- **File:** hook-errors.log
- **Problem:** The dedicated hook error log is essentially empty, while gate-system.log shows active pre-tool-guard warnings about tool density.
- **Why it matters:** Hook errors may be going to gate-system.log instead of hook-errors.log, meaning the dedicated error log is not being used as intended.
- **Fix:** Verify hook error logging destination is correct; if hooks write to gate-system.log instead, consolidate or redirect.

### M-3: 16 agent files contain TODO/FIXME markers
- **Files:** ccount-manager.md:58, AGENTS.md:47, rchitecture-advisor.md:67, ug-fixer.md:514, code-analyzer.md:509, code-builder.md:533, cybersecurity.md:105, delivery-engineer.md:48, expert-tester.md:30, main-coordinator.md:877, project-manager.md:282, qa-engineer.md:46, skill-manager.md:235, support.md:57, 	ech-lead.md:200
- **Problem:** Unfinished markers in shipped agent prompts indicate incomplete work shipped to production.
- **Why it matters:** TODO/FIXME in agent prompts are contractual obligations that haven't been fulfilled — they can mislead the AI about the state of the system.
- **Fix:** Audit each TODO/FIXME marker and either complete the item or create a tracked issue; do not leave markers in shipping agent files.

### M-4: opencode.json uses outputTokenMax: 128000 in experimental block
- **File:** opencode.json:9
- **Problem:** experimental.outputTokenMax is set to 128,000 tokens — nearly the full context window of most models — which leaves minimal headroom for system prompts and tool responses.
- **Why it matters:** With a 128k output limit and a model that may have a 200k context window, the input side (system prompt + tools + conversation history) gets squeezed, risking truncated responses in long sessions.
- **Fix:** Evaluate whether this experimental setting is intentional; if not, remove it or lower the value with testing.

### M-5: AGENTS.md line 204 references gents/main-coordinator.md that doesn't exist as stated
- **File:** AGENTS.md:204
- **Problem:** The note says "Wired: this section is documentation. The actual dispatch logic lives in \gents/main-coordinator.md\'s routing table." The coordinator has a routing table but there is no separate routing config file.
- **Why it matters:** Misleading documentation that refers to a non-existent file path; maintainers may look for the wrong file.
- **Fix:** Update the note to say "lives in \AGENTS.md\'s routing table" or clarify the actual location.

---

## LOW

### L-1: SPECIALIZED_AGENTS.md is an unreferenced aspirational document
- **File:** gents/SPECIALIZED_AGENTS.md
- **Problem:** The file is a CrewAI/LangGraph design reference for a future multi-agent system. It is not referenced from AGENTS.md or any active config.
- **Why it matters:** Low risk as-is, but creates maintenance confusion — it's unclear whether this is still planned, abandoned, or partially implemented.
- **Fix:** Either link it from a roadmap document or move to experiments/ or planning/ with a clear status banner.

### L-2: designer.yaml MCP tools include write but deny edit
- **File:** gents/designer.yaml
- **Problem:** The designer can write files but not edit them — these are usually coupled operations for a design system deliverable.
- **Why it matters:** Minor operational friction; designer may need to overwrite design token files but the deny rule blocks it.
- **Fix:** Reconsider whether edit should be in mcp_tools_denied for the designer agent.

### L-3: skills/awesome-office-hours/sections/ and skills/awesome-ask-questions-if-underspecified/agents/ contain extra files
- **Files:** skills/awesome-office-hours/sections/, skills/awesome-ask-questions-if-underspecified/agents/
- **Problem:** These skill directories contain nested subdirectories (sections/, gents/) with template and config files — unusual for a skill, suggests the skill was scaffolded for a specific project.
- **Why it matters:** Low risk, but these extra nested files increase skill load time and may indicate scope creep in the skill definition.
- **Fix:** Audit whether these nested files are used; if not, remove or archive.

### L-4: opencode.json lacks a top-level opencode.jsonc companion
- **File:** opencode.json
- **Problem:** The config uses only JSON with no JSONC fallback; comments in JSON require a separate .jsonc file convention common in OpenCode configs.
- **Why it matters:** Low risk — but if comments need to be added to the main config, there is no .jsonc convention in use.
- **Fix:** No immediate action; be aware that JSON-only means no inline comments in the primary config.

---

## Verification Commands (Run to Confirm)

| Check | Command | Expected |
|-------|---------|----------|
| Directory structure | \ls -la ~/\.config/opencode/\ | 47 items at root |
| Total lines (AGENTS + agents) | \wc -l AGENTS.md agents/*.md \| tail -1\ | ~10,773 |
| TODO/FIXME count | \g "TODO\|FIXME\|XXX\|BROKEN\|HACK" AGENTS.md agents/*.md --type md \| wc -l\ | ≥15 |
| Potential secrets | \g "sk-[a-zA-Z0-9]{20,}\|api_key\|password\s*=" opencode.json --type json -c\ | 0 hardcoded |
| Report exists | \ls memory/factory/audit/healthcheck-report.md\ | file exists |
| Report has content | \wc -l memory/factory/audit/healthcheck-report.md\ | >100 lines |

---

## Top 3 Findings

1. **C-1 (CRITICAL):** designer.yaml references rontend-design and design skills that do not exist — @designer agent will fail at runtime when it tries to load these skills.
2. **H-2 (HIGH):** main-coordinator.md at 1,358 lines is the largest agent file by 6× — this is the most frequently invoked agent and its bloated prompt is a constant token cost.
3. **M-1 (MEDIUM):** irecrawl-mcp is registered in the agent MCP registry but not configured in opencode.json — MCP server registration is inconsistent with the actual config.

---

## IMMEDIATE User Attention

> **Exposed credential check:** No hardcoded API keys, tokens, or passwords were found in any .json, .md, or .js configuration files. All credential references use {env:VARIABLE_NAME} placeholder pattern. ✅ No action required for credential exposure.

---

*Report generated by code-analyzer. Parallel adversarial audit by expert-tester is running concurrently.*
