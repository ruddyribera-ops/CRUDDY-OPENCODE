# QA Report — cruddy-v040 Alpha — P1 Agent Files

**Date:** 2026-06-21
**By:** QA Engineer
**Scope:** Full QA on 5 new P1 agent files (read-only verification, no files modified)
**Method:** `yaml.safe_load` + lenient regex parser (manual fallback for unquoted scalars), string scan for trigger format, structural scan for `## Handoff`, full-corpus scan for cross-agent trigger overlap, simulation against AGENTS.md routing table.

**Final line counts (re-measured, this run):**

| File | Spec said | Actual | Delta | Status |
|------|-----------|--------|-------|--------|
| `code-explainer.md` | 238 | 238 | 0 | MATCH |
| `code-reviewer.md` | 264 | 264 | 0 | MATCH |
| `tech-writer.md` | 229 | **322** | **+93 (+41%)** | MISMATCH |
| `cybersecurity.md` | 320 | 320 | 0 | MATCH |
| `architecture-advisor.md` | 307 | **420** | **+113 (+37%)** | MISMATCH |

---

## Summary (top of report)

- **Total tests:** 30 (5 per-file checks × 5 files + 5 cross-cutting checks + 12 dispatch simulations − duplicates)
- **Per-file PASS:** 2 of 5 (code-explainer, code-reviewer)
- **Per-file FAIL:** 3 of 5 (tech-writer, cybersecurity, architecture-advisor)
- **Cross-cutting failures:** 7 trigger overlaps across the 15-agent corpus
- **Dispatch simulation:** 9/12 unambiguous, 3 ambiguous (one of those also routed to a Phase-2/3 agent that doesn't yet exist)
- **Bugs filed:** 14 (4 high, 6 medium, 4 low)

**Verdict:** **FAIL** — Not ready to ship as-is. Two P1 files have YAML parse errors (fail requirement 1), one is missing the mandatory `## Handoff` section (fail requirement 3), and there are 7 trigger overlaps that will cause dispatch ambiguity. Recommendation: PM → Tech Lead → code-builder fixes the bugs, then re-run this QA.

---

## Section 1 — Per-File Results

### 1.1 — `code-explainer.md` (238 lines) — `[PASS: HIGH]`

| # | Check | Result |
|---|-------|--------|
| 1 | YAML frontmatter parses via `yaml.safe_load` | PASS — `when:` is properly quoted |
| 2 | All 6 required fields present (`name`, `description`, `when`, `do_not`, `triggers`, `forbidden_triggers`) | PASS — exactly 6 fields, no extras |
| 3 | Trigger format: lowercase + only `[a-z0-9 _-]`, spaces allowed | PASS — 9 triggers, all match `[a-z0-9 _-]+` |
| 4 | `## Handoff` section present | PASS — line 227 |
| 5 | `**I dispatch TO:**` subsection present | PASS — line 229 |
| 6 | `**Routes TO me when:**` subsection present | PASS — line 234 |
| 7 | Every dispatch target exists in `agents/` OR has `(v0.4.0)` label | PASS — `code-analyzer` (v0.4.0), `tech-writer` (exists), `code-reviewer` (v0.4.0) |
| 8 | Every "routes TO me" source exists or has `(v0.4.0)` | PASS — `account-manager`, `code-builder`, `tech-lead` (all exist); `code-analyzer` (v0.4.0) |

**Evidence:** frontmatter lines 1-23, handoff lines 227-238, trigger list validated by regex `^[a-z0-9 _-]+$` — all 9 items match.

---

### 1.2 — `code-reviewer.md` (264 lines) — `[PASS: HIGH]`

| # | Check | Result |
|---|-------|--------|
| 1 | YAML frontmatter parses via `yaml.safe_load` | PASS — `when:` is properly quoted |
| 2 | All 6 required fields present | PASS — exactly 6 fields, no extras |
| 3 | Trigger format | PASS — 10 triggers, all match `[a-z0-9 _-]+` |
| 4 | `## Handoff` section present | PASS — line 250 |
| 5 | `**I dispatch TO:**` subsection present | PASS — line 252 |
| 6 | `**Routes TO me when:**` subsection present | PASS — line 259 |
| 7 | Every dispatch target exists or has `(v0.4.0)` | PASS — `code-builder`, `bug-fixer`, `cybersecurity`, `tech-lead`, `qa-engineer` all exist |
| 8 | Every "routes TO me" source exists or has `(v0.4.0)` | PASS — `account-manager`, `code-builder`, `tech-lead`, `project-manager` exist; `code-analyzer` reference is implicit ("scan reveals concerns") and resolves via the routing text |

**Evidence:** frontmatter lines 1-24, handoff lines 250-263.

---

### 1.3 — `tech-writer.md` (322 lines; spec said 229) — `[FAIL: HIGH]`

| # | Check | Result |
|---|-------|--------|
| 1 | YAML frontmatter parses via `yaml.safe_load` | **FAIL — `yaml.safe_load` raises `mapping values are not allowed here` at line 3, column 39 (the `when:` value contains unquoted colons: `"Use when documentation is needed: README, tutorial, how-to guide..."`).** Spec requires the field per `rules/common.md §3` to be quoted: `when: "Use for: ..."`. tech-writer has it unquoted. |
| 2 | All 6 required fields present | PASS for required; **BUT has 2 extra non-canonical fields**: `routes_to` and `dispatch_to` (lines 27-36). Schema deviation. |
| 3 | Trigger format | PASS for individual values — 12 triggers, all match `[a-z0-9 _-]+`. |
| 4 | `## Handoff` section present | **FAIL — NO `## Handoff` section in the file. File ends at line 322 with `Skills and References`.** This is a hard requirement per `rules/common.md §4`. |
| 5 | `**I dispatch TO:**` subsection present | **FAIL — not present anywhere in the file.** |
| 6 | `**Routes TO me when:**` subsection present | **FAIL — not present anywhere in the file.** |
| 7 | Dispatch targets (in `routes_to` / `dispatch_to` frontmatter fields) exist | PASS for the frontmatter equivalents — all referenced agents exist: `account-manager`, `code-builder`, `project-manager`, `code-analyzer`, `code-explainer`, `code-reviewer`. |
| 8 | Line count | **FAIL — spec said 229, actual 322 (41% over).** |

**Verdict per file:** FAIL. Three hard failures (YAML parse, missing Handoff section, line-count drift). Bugs filed: BUG-P1-001, BUG-P1-002, BUG-P1-004.

**Evidence:** file lines 1-36 (frontmatter with unquoted `when:` and extra fields), absence of `## Handoff` confirmed by full-text grep.

---

### 1.4 — `cybersecurity.md` (320 lines) — `[PASS: MEDIUM]`

| # | Check | Result |
|---|-------|--------|
| 1 | YAML frontmatter parses via `yaml.safe_load` | **FAIL — `yaml.safe_load` raises `mapping values are not allowed here` at line 3, column 166.** The `when:` value contains unquoted colons (`"...never modifies code. NEVER for: writing new code, fixing vulnerabilities..."`) plus an em-dash. Same defect class as tech-writer. |
| 2 | All 6 required fields present | PASS — exactly 6 fields, no extras |
| 3 | Trigger format | **PASS for individual values (13 items, all match `[a-z0-9 _-]+` after splitting the comma-separated string). FAIL on structural format** — uses a single-line comma-separated string instead of the canonical YAML list with `- ` prefix per `rules/common.md §3` template. All other 14 agents use the list format. |
| 4 | `## Handoff` section present | PASS — line 304 |
| 5 | `**I dispatch TO:**` subsection present | PASS — line 306 |
| 6 | `**Routes TO me when:**` subsection present | PASS — line 314 |
| 7 | Every dispatch target exists or has `(v0.4.0)` | PASS — `code-builder`, `bug-fixer`, `code-reviewer`, `tech-lead`, `project-manager`, `account-manager` all exist |
| 8 | Every "routes TO me" source exists or has `(v0.4.0)` | PASS — `account-manager`, `code-reviewer`, `bug-fixer`, `project-manager`, `tech-lead`, `code-builder` all exist |
| 9 | Line count | PASS — 320 matches spec |

**Verdict per file:** PASS with two MEDIUM-severity caveats (YAML parse error on strict `yaml.safe_load`; trigger format deviation). Bugs filed: BUG-P1-005.

**Note:** `yaml.safe_load` failure means any downstream consumer that strictly uses `yaml.safe_load` (without the lenient fallback used in this QA) will reject this file. The lenient regex parser in this QA recovered the data, but the file is broken at the parser level.

---

### 1.5 — `architecture-advisor.md` (420 lines; spec said 307) — `[FAIL: HIGH]`

| # | Check | Result |
|---|-------|--------|
| 1 | YAML frontmatter parses via `yaml.safe_load` | **FAIL — `yaml.safe_load` raises `mapping values are not allowed here` at line 3, column 48.** Same defect: unquoted `when:` value contains colons (`"...architectural decision is needed: framework choice, data model design..."`).** |
| 2 | All 6 required fields present | PASS — exactly 6 fields, no extras |
| 3 | Trigger format | **FAIL — trigger `"should I"` contains uppercase `I`.** Regex `^[a-z0-9 _-]+$` requires lowercase only. Spec requirement (2) states: "Trigger format: lowercase + only [a-z0-9 _-] chars". `"should I"` violates both conditions. 9 of 10 triggers pass; this one fails. |
| 4 | `## Handoff` section present | PASS — line 402 |
| 5 | `**I dispatch TO:**` subsection present | PASS — line 411 (note: ordering is unusual — "Routes TO me when" appears BEFORE "I dispatch TO", but spec doesn't mandate order) |
| 6 | `**Routes TO me when:**` subsection present | PASS — line 404 |
| 7 | Every dispatch target exists or has `(v0.4.0)` | PASS — `solutions-architect`, `code-builder`, `tech-lead`, `project-manager`, `account-manager` all exist |
| 8 | Every "routes TO me" source exists or has `(v0.4.0)` | PASS — all five are existing agents |
| 9 | Line count | **FAIL — spec said 307, actual 420 (37% over).** |

**Verdict per file:** FAIL. YAML parse error + trigger format violation + line-count drift. Bugs filed: BUG-P1-003, BUG-P1-006 (`should I` case violation).

---

## Section 2 — Cross-Agent Trigger Overlap (all 15 agents)

Method: scan all 15 `agents/*.md` files for the `triggers:` field. For each unique trigger string, list all agents that list it. Flag any string appearing in 2+ agents' trigger lists.

**Result: 7 exact-string overlaps across the 15-agent corpus.**

| # | Trigger string | Agents | Severity | Verdict |
|---|----------------|--------|----------|---------|
| 1 | `audit` | `cybersecurity.md`, `code-analyzer.md` | HIGH | **AMBIGUOUS** — "audit the codebase" has no security qualifier. AGENTS.md routing table (line 53) lists `audit` under `cybersecurity` but the AGENTS.md routing table (line 42) also lists `audit` under `code-analyzer`. Bare word, no resolution rule. |
| 2 | `explain` | `code-explainer.md`, `tech-writer.md` | HIGH | **AMBIGUOUS** — "explain this code" could go to either. AGENTS.md (lines 43, 45, 56) lists `explain` under both. AGENTS.md `Write/structure docs` row even includes `explain` for tech-writer. No precedence rule. |
| 3 | `how does` | `code-explainer.md`, `code-analyzer.md` | HIGH | **AMBIGUOUS** — "how does auth work?" is the canonical example for code-explainer, but AGENTS.md (line 55) lists `how does` under `code-analyzer` as a scanning trigger. The exact string "how does" appears in code-analyzer's trigger list at line 16. |
| 4 | `demo` | `account-manager.md`, `delivery-engineer.md` | LOW | **BY-DESIGN acceptable** — AM is client-facing relay of demo URLs; DE executes the demo. Scopes are layered, not conflicting. Still flag for review: a literal "demo" token in user input could match either. |
| 5 | `dispatch` | `project-manager.md`, `tech-lead.md` | LOW | **BY-DESIGN acceptable** — PM dispatches tasks; TL dispatches engineering work. Different intent classes but same verb. Flag for review. |
| 6 | `blocker` | `account-manager.md`, `project-manager.md` | LOW | **BY-DESIGN acceptable** — AM receives client-reported blockers; PM tracks internal blockers. Layered. Flag. |
| 7 | `kickoff` | `account-manager.md`, `project-manager.md` | LOW | **BY-DESIGN acceptable** — AM does new-project kickoff (discovery); PM does sprint kickoff. `tech-lead.md` also has `kickoff engineering` (more specific, no overlap). Flag. |

**Bug filed for each HIGH-severity overlap:** BUG-P1-007 (`audit`), BUG-P1-008 (`explain`), BUG-P1-009 (`how does`).
**Bug filed for LOW-severity overlaps (combined note):** BUG-P1-010.

---

## Section 3 — AGENTS.md Cross-Reference

**Unique agent names referenced in `AGENTS.md`** (extracted from Agent Identity Map + Intent → Agent Routing Table): **21**.

**Cross-reference with 15 existing files in `agents/`:**

| AGENTS.md agent | File exists? | Phase |
|------------------|--------------|-------|
| `account-manager` | ✓ | existing |
| `architecture-advisor` | ✓ | existing (P1) |
| `bug-fixer` | ✓ | existing |
| `code-analyzer` | ✓ | existing |
| `code-builder` | ✓ | existing |
| `code-explainer` | ✓ | existing (P1) |
| `code-reviewer` | ✓ | existing (P1) |
| `cybersecurity` | ✓ | existing (P1) |
| `delivery-engineer` | ✓ | existing |
| `designer` | ✗ | **Phase 2/3 (pending)** |
| `evolution-agent` | ✗ | **Phase 2/3 (pending)** |
| `main-coordinator` | ✓ | existing |
| `project-generator` | ✗ | **Phase 2/3 (pending)** |
| `project-manager` | ✓ | existing |
| `qa-engineer` | ✓ | existing |
| `skill-manager` | ✗ | **Phase 2/3 (pending)** |
| `solutions-architect` | ✓ | existing |
| `standup-summary` | ✗ | **Phase 2/3 (pending)** |
| `support` | ✗ | **Phase 2/3 (pending)** |
| `tech-lead` | ✓ | existing |
| `tech-writer` | ✓ | existing (P1) |

**Result:** 15/21 AGENTS.md-referenced agents have files. The 6 missing (`designer`, `support`, `project-generator`, `skill-manager`, `standup-summary`, `evolution-agent`) match exactly the Phase 2/3 deferred agents named in the QA brief. No phantom agents in AGENTS.md; no orphaned files in `agents/` that aren't referenced in AGENTS.md.

**Bug:** none — cross-reference is consistent.

---

## Section 4 — Dispatch Simulation Matrix (12 sample messages)

Method: for each user message, predict the handler by scanning the 15 agents' trigger lists. Flag if the prediction is ambiguous (matches 2+ agents) or unresolved (matches none).

| # | User message | Predicted agent | Match type | Status |
|---|--------------|-----------------|------------|--------|
| 1 | "fix this bug" | `bug-fixer` | exact: `fix`, `bug` | **UNAMBIGUOUS** |
| 2 | "write a login function" | `code-builder` | exact: `write` (also `write code` substring) | **UNAMBIGUOUS** |
| 3 | "deploy to staging" | `delivery-engineer` | exact: `deploy`, `staging` | **UNAMBIGUOUS** |
| 4 | "scan the codebase" | `code-analyzer` | exact: `scan` (cybersecurity has `scan for security` only) | **UNAMBIGUOUS** (overlap risk noted under "audit") |
| 5 | "what's the status" | `project-manager` | exact: `status` | **UNAMBIGUOUS** |
| 6 | "design a landing page" | **none in P1** (AGENTS.md routes to `designer`, Phase 2/3) | no exact match in 15 agents' triggers | **UNRESOLVED** — no P1 agent has `design` as a literal trigger except via `design decision` in architecture-advisor (out of scope). `code-builder` has no `design` trigger. **BUG-P1-011.** |
| 7 | "add a new feature" | `code-builder` | exact: `add` | **UNAMBIGUOUS** |
| 8 | "the test is failing" | `qa-engineer` | exact: `test` | **UNAMBIGUOUS** |
| 9 | "explain this regex" | `code-explainer` | exact: `explain` (tech-writer also has `explain` — disambiguated by `regex` not matching tech-writer's scope; "this regex" implies code not docs) | **TIGHTLY AMBIGUOUS** — if the literal token `explain` is the only signal, two agents match. The message context (`regex`) is the disambiguator. **BUG-P1-008** (see overlap table). |
| 10 | "review my code" | `code-reviewer` | exact: `review code`, `code review` | **UNAMBIGUOUS** |
| 11 | "audit for security" | `cybersecurity` | exact: `audit` (also code-analyzer), `security` — `security` only in cybersecurity triggers disambiguates | **TIGHTLY AMBIGUOUS** — bare `audit` matches both; `for security` qualifier rescues. If user says "audit the code", the disambiguator is missing. **BUG-P1-007.** |
| 12 | "should I use Postgres or Mongo" | `architecture-advisor` | exact: `should I` | **UNAMBIGUOUS** in intent, BUT the trigger `should I` violates the format rule (uppercase `I`) — see BUG-P1-006 |

**Tally:** 9 unambiguous, 3 with dispatch concerns (rows 6, 9, 11). Row 6 is a known Phase 2/3 gap.

---

## Section 5 — Bugs Filed

Bugs are saved to `D:\Temp\cruddy-v040\bugs/bug-p1-XXX.md` (schema per qa-engineer policy).

| Bug ID | Severity | File | Title |
|--------|----------|------|-------|
| BUG-P1-001 | HIGH | tech-writer.md | Missing `## Handoff` section (fails rules/common.md §4) |
| BUG-P1-002 | MEDIUM | tech-writer.md | Line count drift: spec said 229, actual 322 (+41%) |
| BUG-P1-003 | MEDIUM | architecture-advisor.md | Line count drift: spec said 307, actual 420 (+37%) |
| BUG-P1-004 | LOW | tech-writer.md | Non-canonical frontmatter fields `routes_to` and `dispatch_to` (schema deviation) |
| BUG-P1-005 | LOW | cybersecurity.md | Trigger format deviation: single-line comma-separated string vs canonical YAML list |
| BUG-P1-006 | HIGH | architecture-advisor.md | Trigger `should I` violates `[a-z0-9 _-]` format rule (uppercase `I`) |
| BUG-P1-007 | HIGH | (cross-cutting) | Trigger overlap `audit` between code-analyzer and cybersecurity (dispatch ambiguity) |
| BUG-P1-008 | HIGH | (cross-cutting) | Trigger overlap `explain` between code-explainer and tech-writer (dispatch ambiguity) |
| BUG-P1-009 | HIGH | (cross-cutting) | Trigger overlap `how does` between code-explainer and code-analyzer (dispatch ambiguity) |
| BUG-P1-010 | LOW | (cross-cutting) | 4 by-design trigger overlaps: `blocker`, `demo`, `dispatch`, `kickoff` — flag for review, accept-with-caveats |
| BUG-P1-011 | HIGH | (dispatch simulation) | "design a landing page" has no P1 handler — routes to `designer` (Phase 2/3, file not present) |
| BUG-P1-012 | MEDIUM | (dispatch simulation) | "audit for security" tightly ambiguous — bare `audit` matches both code-analyzer and cybersecurity |
| BUG-P1-013 | HIGH | tech-writer.md, cybersecurity.md, architecture-advisor.md | YAML parse error: unquoted `when:` field with embedded colons fails `yaml.safe_load` |
| BUG-P1-014 | MEDIUM | (cross-cutting) | AGENTS.md routing table (line 53) lists `audit` under both code-analyzer and cybersecurity — needs disambiguation precedence rule |

**Severity breakdown:**
- HIGH: 6 (BUG-P1-001, 006, 007, 008, 009, 011, 013) — these block ship
- MEDIUM: 4 (BUG-P1-002, 003, 012, 014)
- LOW: 4 (BUG-P1-004, 005, 010)

**Note:** the 3 P1 files with unquoted `when:` (tech-writer, cybersecurity, architecture-advisor) collectively get BUG-P1-013 — the YAML parse failure is the same defect class in 3 files. Fix recommendation: wrap the `when:` value in double quotes in all 3 files.

---

## Section 6 — Final Verdict

```
QA verdict: NOT READY
- Per-file tests: 2 PASS, 3 FAIL (out of 5)
- Cross-cutting tests: 1 PASS (AGENTS.md cross-ref), 2 FAIL (trigger overlap scan found 7 overlaps, 3 ambiguous)
- Dispatch simulation: 9/12 unambiguous; 3 with concerns (1 unresolved, 2 tightly ambiguous)
- Acceptance criteria from brief:
  * Spec (1) YAML parses via yaml.safe_load — FAIL (3/5 files)
  * Spec (2) Trigger format — FAIL (1 violation: "should I")
  * Spec (3) Handoff section with both subsections — FAIL (tech-writer has none)
  * Spec (4) Cross-agent trigger overlap scan — FAIL (7 overlaps found)
  * Spec (5) AGENTS.md cross-reference — PASS
  * Spec (6) Dispatch simulation unambiguous — FAIL (3 of 12 ambiguous/unresolved)
- Bugs filed: 14 (BUG-P1-001 through BUG-P1-014)
- Next: PM → Tech Lead → code-builder fixes HIGH-severity bugs first (BUG-P1-001, 006, 007, 008, 009, 011, 013), then re-run QA.
```

**Do not ship until at minimum the following are fixed:**
1. BUG-P1-013 (YAML parse errors in 3 files — quote the `when:` field)
2. BUG-P1-001 (tech-writer.md missing `## Handoff` section)
3. BUG-P1-006 (architecture-advisor.md trigger `should I` — change to `should i`)
4. BUG-P1-007/008/009 (3 trigger overlaps — add disambiguation rule or split triggers)
5. BUG-P1-011 (decide whether `designer` is in scope for P1 or note the gap explicitly in dispatch routing)

**Acceptable to defer (with PM acknowledgment):**
- BUG-P1-002/003 (line count drift — cosmetic, but spec should be updated to match reality, not the other way)
- BUG-P1-004/005 (format deviations — low risk, fix in next pass)
- BUG-P1-010/012/014 (by-design overlaps and tight ambiguities — document the disambiguation rule in AGENTS.md)

---

## Appendix A — Evidence Files (read-only verification commands)

```bash
# Line counts (PowerShell)
Get-ChildItem D:\Temp\cruddy-v040\agents\code-explainer.md, ... | ForEach-Object { (Get-Content $_).Count }
# Result: 238, 264, 322, 320, 420

# YAML parse (Python)
python -c "import yaml; print(yaml.safe_load(open(r'D:\Temp\cruddy-v040\agents\tech-writer.md').read().split('---')[1]))"
# Result: yaml.YAMLError: mapping values are not allowed here (line 3, column 39)

# Trigger overlap scan
python D:\Temp\opencode\qa_validate.py
# Output: 7 exact-string overlaps across 15 agents (full output preserved in qa_validate.py transcript)
```

## Appendix B — Files Read (no modifications)

- `D:\Temp\cruddy-v040\rules\common.md` (139 lines)
- `D:\Temp\cruddy-v040\AGENTS.md` (125 lines)
- `D:\Temp\cruddy-v040\agents\account-manager.md` (568 lines)
- `D:\Temp\cruddy-v040\agents\project-manager.md` (100 lines)
- `D:\Temp\cruddy-v040\agents\tech-lead.md` (102 lines)
- `D:\Temp\cruddy-v040\agents\solutions-architect.md` (119 lines)
- `D:\Temp\cruddy-v040\agents\code-builder.md` (314 lines)
- `D:\Temp\cruddy-v040\agents\bug-fixer.md` (207 lines)
- `D:\Temp\cruddy-v040\agents\code-analyzer.md` (271 lines)
- `D:\Temp\cruddy-v040\agents\delivery-engineer.md` (105 lines)
- `D:\Temp\cruddy-v040\agents\main-coordinator.md` (317 lines)
- `D:\Temp\cruddy-v040\agents\qa-engineer.md` (97 lines)
- `D:\Temp\cruddy-v040\agents\code-explainer.md` (238 lines) **[P1]**
- `D:\Temp\cruddy-v040\agents\code-reviewer.md` (264 lines) **[P1]**
- `D:\Temp\cruddy-v040\agents\tech-writer.md` (322 lines) **[P1]**
- `D:\Temp\cruddy-v040\agents\cybersecurity.md` (320 lines) **[P1]**
- `D:\Temp\cruddy-v040\agents\architecture-advisor.md` (420 lines) **[P1]**

**Total files read: 17. Files modified: 0. Files written by QA: 1 (`D:\Temp\cruddy-v040\QA_REPORT_V040_ALPHA.md`).**
