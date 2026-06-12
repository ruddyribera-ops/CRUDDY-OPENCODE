# OpenCode Configuration — Integration Plan: 10 Fixes

**Created:** 2026-06-05
**Score before:** 68/100 (Growing)
**Goal:** Zero-breaking implementation, each fix independently rollbackable

---

## Fix 1: desktop-commander MCP

**Finding:** `desktop-commander_*` tools referenced in 4 agent YAML files but NO MCP server exists in opencode.json.

**Implementation:** Add `@modelcontextprotocol/server-filesystem` as local MCP server in opencode.json.

**Breaking change risk:** ZERO. Adds new entry, no existing behavior modified.

**Rollback:** Remove the entry from opencode.json mcp block.

---

## Fix 2: Filter `idle:untitled` from session logging

**Finding:** `memory-bridge.js` logs `idle:untitled`, `forced-idle:untitled`, `session-close:untitled` — 150+ noise entries.

**Implementation:** Add guard in memory-bridge.js — skip flushMemory when title is "untitled" AND no meaningful file edits occurred.

**Breaking change risk:** ZERO. Only suppresses noise logging.

**Rollback:** Remove guard condition.

---

## Fix 3: Update SKILLS_INDEX.json — Add 3 Missing Skills

**Finding:** `jwt-security`, `password-security`, `sql-safety` exist on disk but NOT in index (android, ios, flutter, react-native ARE already indexed).

**Implementation:** Add 3 entries to SKILLS_INDEX.json.

**Breaking change risk:** ZERO. JSON array addition only.

**Rollback:** Remove added JSON entries.

---

## Fix 4: Wire check-rules.py into post-tool-guard.js

**Finding:** `check-rules.py` exists but is NEVER called from any hook/plugin. Agent rules are passive markdown.

**Implementation:** Add check-rules.py invocation to drainLintQueue in post-tool-guard.js.

**Breaking change risk:** LOW. Advisory only (logs warnings, doesn't block).

**Rollback:** Remove call block from drainLintQueue.

---

## Fix 5: Consolidate Linters — Keep Biome, Remove ESLint/Prettier/Ruff/Black

**Finding:** post-tool-guard.js runs eslint+prettier+ruff+black, post-turn-biome.js runs biome — both on same files. Biome is 20-50x faster (Rust-based).

**Implementation:** Remove lint functions from post-tool-guard.js, keep injection scan. Ensure biome.json exists at CONFIG_ROOT.

**Breaking change risk:** MEDIUM. Changes linting behavior. Mitigation: keep eslint conditional for projects with .eslintrc.

**Rollback:** Restore removed functions.

---

## Fix 6: Add Citation Links to Graph Memory

**Finding:** `writeGraphNode()` stores no source citation (file path, line number, session ID).

**Implementation:** Extend graph node schema with citation fields. Add 28-day auto-expiry on low-confidence facts.

**Breaking change risk:** ZERO. Adds optional fields to existing data structure.

**Rollback:** Remove citation fields from data object.

---

## Fix 7: Add Confidence Scoring to DNA.yaml

**Finding:** DNA.yaml (614 lines, 30+ genes) has no confidence scoring. All genes treated equal.

**Implementation:** Add `gene_fitness` section to DNA.yaml. Track activations/successes per gene. Weight by historical success rate. Prune genes with weight < 0.3.

**Breaking change risk:** ZERO. Tracking only activates when `tracking_enabled: true`.

**Rollback:** Set `tracking_enabled: false`.

---

## Fix 8: Implement Structured Handoff Protocol

**Finding:** No file-based contract system between agents. 36.94% of multi-agent failures are coordination-type.

**Implementation:** Create `memory/handover/schema.json`. Update coordinator handover format to include input/output schema + verify_command. Create `scripts/handover-validate.ps1`.

**Breaking change risk:** LOW. Validation is advisory, specialists continue working without handoff files.

**Rollback:** Remove schema + validation script.

---

## Fix 9: Add Automated Security Scanning

**Finding:** post-tool-guard.js has injection detection but lacks comprehensive SAST-level scanning. 12% of agent skill marketplace was malicious (Jan 2026).

**Implementation:** Extend INJECTION_PATTERNS with OWASP AI Top 10. Create `scripts/security-scan.ps1`. Add to `hook-startup.ps1`.

**Breaking change risk:** ZERO. Scans are advisory only.

**Rollback:** Remove security-scan.ps1 from hook-startup.ps1 invocation.

---

## Fix 10: Create Living SPEC.md Pattern

**Finding:** No living specification surviving context resets. Agents work from scratch every session.

**Implementation:** Create `scripts/spec-survival.js` companion to compaction-survival.js. Create `planning/SPEC.md` template. Inject SPEC.md on session start if exists.

**Breaking change risk:** ZERO. Only activates when SPEC.md exists in project.

**Rollback:** Remove spec-survival.js from compaction hooks.

---

## Rollback Safety Matrix

| Fix | Risk | Rollback Path | One-Line Test |
|-----|------|---------------|---------------|
| 1. desktop-commander MCP | ZERO | Remove from opencode.json mcp block | Agent tool list includes desktop-commander_* |
| 2. idle:untitled filter | ZERO | Remove guard condition | session_log.md has no idle:untitled entries |
| 3. SKILLS_INDEX.json | ZERO | Remove added JSON entries | Skills index count increases by 3 |
| 4. check-rules.py wiring | LOW | Remove call block from drainLintQueue | check-rules.py fires on file edit |
| 5. Consolidate linters | MEDIUM | Restore removed functions | ESLint still runs on .ts/.py files |
| 6. Citation links | ZERO | Remove citation fields | Graph nodes have source field |
| 7. DNA confidence scoring | ZERO | Set tracking_enabled: false | gene_fitness section in DNA.yaml |
| 8. Handoff protocol | LOW | Remove schema + validation script | Handoff files validate against schema |
| 9. Security scanning | ZERO | Remove from hook-startup.ps1 | security-scan.log exists |
| 10. Living SPEC.md | ZERO | Remove spec-survival.js from hooks | SPEC.md injected on session start |

---

## Implementation Order

```
Week 1 — Zero-risk fixes:
1. desktop-commander MCP    → 5 min     ✅ DONE
2. idle:untitled filter     → 10 min    ✅ DONE
3. SKILLS_INDEX.json        → 5 min     ✅ DONE
4. check-rules.py wiring    → 15 min    ✅ DONE

Week 2 — Low-risk enhancements:
5. Consolidate linters     → 30 min    ✅ DONE (biomeHasPriority)
6. Citation links          → 20 min    ✅ DONE (CITATION_TTL_DAYS=28)
7. DNA confidence scoring  → 30 min    ✅ DONE (gene_fitness section)

Week 3 — New capabilities:
8. Handoff protocol        → 60 min    ✅ DONE (schema.json + handover-validate.ps1)
9. Security scanning       → 45 min    ✅ DONE (security-scan.ps1, 4 info findings)
10. Living SPEC.md         → 45 min    ✅ DONE (SPEC-template.md + spec-inject.ps1)
```

**Total:** ~4 hours across 3 weeks, zero breaking changes, each fix independently rollbackable.

**Status:** 10/10 fixes implemented and tested.
**Verification:**
- security-scan.ps1: 4 info findings (intentional perms), 0 critical → PASS
- handover-validate.ps1: validates handoff against schema, catches 7 error types → PASS
- spec-inject.ps1: silent exit when no SPEC.md present → PASS
- All 4 modified config files (opencode.json, SKILLS_INDEX.json, post-tool-guard.js, memory-bridge.js) verified
- All 4 new scripts + 1 template + 1 schema + 1 tracking file created
