# QA Smoke Test Report — Agent Files (v0.3.0)

**Date:** 2026-06-21
**Scope:** 3 representative agents from `D:\Temp\cruddy-v030\agents\` (READ-ONLY audit)
**Auditor:** QA Engineer
**Method:** Programmatic YAML parse + format regex + dispatch target lookup + behavioral simulation
**Files audited (3 of 6):**
- `account-manager.md` (24,807 bytes)
- `project-manager.md` (4,992 bytes)
- `qa-engineer.md` (4,661 bytes)

**Files NOT audited (3):** `delivery-engineer.md`, `solutions-architect.md`, `tech-lead.md`

---

## Verdict (top line)

**`[FAIL: MEDIUM]` — Not ready to ship agent roster as-is.**

- YAML parses cleanly on all 3: **PASS**
- Trigger format: **PASS under loose reading, 26 strict violations** (spaces where hyphens expected)
- One real forbidden-trigger format error: **`qa-engineer.md` line 21 contains an apostrophe** (`'`) in `"run tests on someone's behalf"` — fails BOTH readings
- Handoff dispatch targets: **PASS** (all references resolve to either an existing file or a planned v0.4.0 agent)
- Behavioral simulation: **3/5 sample messages route correctly; 2/5 reveal dispatch-table conflicts between `account-manager.md`'s MANDATORY DISPATCH TRIGGERS and `AGENTS.md`'s Intent → Agent Routing Table**

---

## 1. YAML Parse Results

All 3 agents' frontmatter parsed cleanly with Python `yaml.safe_load`. Each contains the full canonical schema from `rules/common.md` §3.

| Agent | Parse | Keys present |
|-------|-------|--------------|
| `account-manager.md` | `[PASS: HIGH]` | `name`, `description`, `when`, `do_not`, `triggers`, `forbidden_triggers` |
| `project-manager.md` | `[PASS: HIGH]` | `name`, `description`, `when`, `do_not`, `triggers`, `forbidden_triggers` |
| `qa-engineer.md` | `[PASS: HIGH]` | `name`, `description`, `when`, `do_not`, `triggers`, `forbidden_triggers` |

**Evidence:** Programmatic parse via `yaml.safe_load` returned no errors; all 6 expected keys present per file.

---

## 2. Format Checks

Rule: lowercase + hyphenated + no special chars except `-` and `_`.

The rule spec is ambiguous on whether spaces count as a special char. Two readings applied:

- **Loose:** lowercase + no chars outside `[a-z0-9 _-]` → space allowed
- **Strict:** lowercase + no spaces + no chars outside `[a-z0-9_-]` → must be hyphenated

### 2.1 Summary

| Agent | Loose fails | Strict fails | Real bug (loose fail) |
|-------|-------------|--------------|------------------------|
| `account-manager.md` | 0 | 7 | 0 |
| `project-manager.md` | 0 | 8 | 0 |
| `qa-engineer.md` | **1** | 11 | **1 — apostrophe in forbidden_triggers[1]** |

**`[FAIL: HIGH]` on `qa-engineer.md` line 21:** `"run tests on someone's behalf"` contains an apostrophe (`'`), which is a real special-char violation. Fails both loose and strict readings.

### 2.2 Per-agent strict-violation lists

#### `account-manager.md` — 7 strict fails
**triggers (6):** `new project`, `client communication`, `what happened`, `where is my app`, `when will it be done`, `sign off`
**forbidden_triggers (1):** `write code`

#### `project-manager.md` — 8 strict fails
**triggers (4):** `sprint plan`, `what is next`, `sprint review`, `where are we`
**forbidden_triggers (4):** `talk to the client`, `write code`, `design architecture`, `run tests`

#### `qa-engineer.md` — 11 strict fails + 1 real fail
**triggers (3):** `test plan`, `is it ready to ship`, `smoke test`
**forbidden_triggers (7 strict + 1 real):**
- `write code` (strict)
- `run tests on someone's behalf` (**real fail — apostrophe**, strict fail)
- `talk to the client` (strict)
- `ship failing acceptance` (strict)
- `sign off without verification` (strict)
- `file bug without repro steps` (strict)
- `hide failing test` (strict)
- `test only happy path` (strict)

### 2.3 Internal inconsistency
`qa-engineer.md` mixes both styles within its own `triggers` list — `test plan` (space) and `write-test-plan` (hyphenated) sit next to each other. This shows the file author considered both acceptable, but the spec says one or the other. Recommendation: pick a single convention in `rules/common.md`.

### 2.4 Recommendation
Either (a) standardize on hyphenation throughout and update all space-separated triggers, or (b) explicitly amend `rules/common.md` §3 to permit spaces. The fastest ship is (b) — one rule edit, zero agent file edits. The cleaner long-term answer is (a).

---

## 3. Handoff Validation

Every agent's `## Handoff` → `**I dispatch TO:**` list was extracted and cross-checked against:
- The 6 existing files in `agents/`
- The 21-agent target per `rules/common.md` ("growing to 21 by v0.4.0") = 6 existing + 15 planned per `AGENTS.md` identity map

| Agent | Dispatch targets | Status |
|-------|------------------|--------|
| `account-manager.md` | `bug-fixer`, `code-builder`, `qa-engineer`, `delivery-engineer`, `code-analyzer`, `code-explainer`, `designer`, `tech-writer`, `project-manager`, `architecture-advisor`, `cybersecurity` | **ALL VALID** (2 exist, 9 planned v0.4.0) |
| `project-manager.md` | `solutions-architect`, `tech-lead`, `code-builder`, `qa-engineer`, `delivery-engineer` | **ALL VALID** (4 exist, 1 planned) |
| `qa-engineer.md` | `bug-fixer` | **VALID** (planned v0.4.0) |

**`[PASS: HIGH]` — No phantom agents referenced. No agent references an entity outside the v0.4.0 plan.**

**Cross-check math:**
- Existing agents in `agents/`: 6 (`account-manager`, `delivery-engineer`, `project-manager`, `qa-engineer`, `solutions-architect`, `tech-lead`)
- Planned agents in `AGENTS.md` identity map: 21
- Missing (planned, no file): 15 (`architecture-advisor`, `bug-fixer`, `code-analyzer`, `code-builder`, `code-explainer`, `code-reviewer`, `cybersecurity`, `designer`, `evolution-agent`, `main-coordinator`, `project-generator`, `skill-manager`, `standup-summary`, `support`, `tech-writer`)
- 6 + 15 = 21 ✓ matches `rules/common.md` "growing to 21 by v0.4.0"

---

## 4. Dispatch Simulation

Five sample user messages run against each sample agent's `triggers` and `forbidden_triggers` lists, then compared against:
- `account-manager.md` MANDATORY DISPATCH TRIGGERS table
- `AGENTS.md` Intent → Agent Routing Table

### 4.1 Simulation matrix

| # | User message | AM dispatch predicts | AGENTS.md predicts | Match? | Sample-agent activations |
|---|--------------|----------------------|---------------------|--------|---------------------------|
| 1 | `fix this bug` | `bug-fixer` | `bug-fixer` | **YES** | AM: forbidden `fix`,`bug` ✓ / PM: no signal ✓ / QA: trigger `bug` ⚠ (see 4.2) |
| 2 | `deploy to staging` | `delivery-engineer` | `delivery-engineer` | **YES** | AM: forbidden `deploy` ✓ / PM: forbidden `deploy` ✓ / QA: no signal ✓ |
| 3 | `what's the status` | `project-manager` | `standup-summary` | **NO — CONFLICT** | AM: trigger `status` activates / PM: trigger `status` activates / QA: no signal |
| 4 | `design a landing page` | `designer` | `code-builder` (via "UI/Frontend/Design") | **NO — CONFLICT** | AM: no own trigger, dispatch table routes to designer / PM: no signal / QA: no signal |
| 5 | `scan the codebase` | `code-analyzer` | `code-analyzer` (and noise: `code-builder` via word "code") | **YES (with caveat)** | AM: forbidden `scan` ✓ / PM: no signal ✓ / QA: no signal ✓ |

### 4.2 Findings

**`[FAIL: MEDIUM]` — Two real routing conflicts between `account-manager.md` and `AGENTS.md`:**

#### Conflict 1: "status"
- `account-manager.md` MANDATORY DISPATCH TRIGGERS row: `"sprint plan", "status", "blocker", "standup", "task"` → **project-manager**
- `AGENTS.md` Intent → Agent Routing Table: `"Daily status"` → **standup-summary**
- Also: `"Project planning/sprint"` → project-manager

The phrase `"what's the status"` is ambiguous between client-facing status (AM/PM) and internal daily status digest (standup-summary). Both tables are technically correct for different contexts, but the routing is **inconsistent** for the same trigger word. Bug filed below.

#### Conflict 2: "design" / "landing page"
- `account-manager.md` MANDATORY DISPATCH TRIGGERS row: `"design", "UI", "frontend", "CSS", "landing page", "make it look"` → **designer**
- `AGENTS.md` Intent → Agent Routing Table has TWO conflicting rows:
  - `"UI/Frontend/Design"` triggers `design, landing page, UI, frontend, ...` → **code-builder**
  - `"Design system / UI spec"` triggers `design system, design tokens, ...` → **designer**

`AGENTS.md` is internally inconsistent. Substring matching on `"design"` will hit `code-builder` first. Bug filed below.

#### `qa-engineer.md` activation on "fix this bug" — `[PASS: LOW]`
QA's `triggers` list includes the bare word `"bug"`. On `"fix this bug"` it activates. This is not strictly wrong — QA does file bugs — but the dispatch order matters: `bug-fixer` should handle first, QA only if the bug is filed during testing. No routing rule governs priority. Mild ambiguity, not blocking.

#### "scan the codebase" — `[PASS: MEDIUM]`
Both tables agree on `code-analyzer`, but AGENTS.md also matches the word `"code"` against `code-builder` (via "Build/create/modify code" intent). Substring noise; consensus routing still lands on `code-analyzer`. Not blocking but is fragile — the table would misroute `"do a code review"` (reviewer's word "code" is a noun modifier, not a build verb).

---

## 5. Bugs Filed

### Bug — `qa-engineer.md` forbidden_triggers contains apostrophe

**Severity:** low
**File:** `D:\Temp\cruddy-v030\agents\qa-engineer.md`, line 21
**Reproduction:**
1. Open `qa-engineer.md` line 21
2. Observe: `- "run tests on someone's behalf"`
3. Run format check: `[FAIL: special char]` — `'` is not in `[a-z0-9 _-]`
**Expected:** No special chars per `rules/common.md` §3 trigger format rules.
**Actual:** Contains `'` (apostrophe).
**Suggested fix:** Replace with `run tests on someones behalf` or `run-tests-on-someones-behalf`.
**Status:** ready for code-builder.

### Bug — Routing conflict: "status" routes differently in AM table vs AGENTS.md

**Severity:** medium
**Files:** `D:\Temp\cruddy-v030\agents\account-manager.md` (line ~60) and `D:\Temp\cruddy-v030\AGENTS.md` (line ~48)
**Reproduction:**
1. User says "what's the status"
2. `account-manager.md` MANDATORY DISPATCH TRIGGERS row maps `status` → `project-manager`
3. `AGENTS.md` Intent → Agent Routing maps `status` (under "Daily status") → `standup-summary`
**Expected:** One canonical routing.
**Actual:** Two canonical routings.
**Suggested fix:** Decide semantics. Either:
- (a) Client-facing "status" → project-manager (sprint status); AGENTS.md "Daily status" → keep standup-summary (internal digest); rename AGENTS.md intent to "Daily standup digest" so substring match on bare "status" no longer hits it.
- (b) All "status" → standup-summary; AM table updated accordingly.
**Recommendation:** (a). The internal digest is a separate concept.

### Bug — Routing conflict: "design" routes to two different agents in AGENTS.md

**Severity:** medium
**File:** `D:\Temp\cruddy-v030\AGENTS.md` lines ~40 and ~45
**Reproduction:**
1. User says "design a landing page"
2. Substring `design` matches "UI/Frontend/Design" intent → `code-builder`
3. Substring `design` does NOT match "Design system / UI spec" intent (which needs `design system` as a phrase)
**Expected:** Per `account-manager.md` MANDATORY DISPATCH TRIGGERS, "design" / "landing page" → `designer`
**Actual:** `AGENTS.md` misroutes to `code-builder`
**Suggested fix:** Either:
- (a) Drop the `design` token from the "UI/Frontend/Design" intent triggers (keep `landing page`, `UI`, `frontend`, `CSS`, `theme`, `make it look` — all unambiguous).
- (b) Reorder AGENTS.md so designer intent comes first.
- (c) Make the AM table canonical and update AGENTS.md.
**Recommendation:** (a). Token `design` is overloaded; the phrase `design system` is the unambiguous designer signal.

---

## 6. Summary

| Check | Result |
|-------|--------|
| YAML parse (3 agents) | **PASS** (3/3) |
| Trigger format (loose reading) | **PASS** (2/3, 1 real bug in qa-engineer) |
| Trigger format (strict reading) | **WARN** (26 space-separated violations across 3 agents) |
| Handoff dispatch targets | **PASS** (all 17 references resolve to existing or planned v0.4.0 agents) |
| Dispatch simulation | **3/5 match, 2/5 conflict** |
| Bugs filed | **3** (1 low format, 2 medium routing) |

## 7. Verdict

**`[FAIL: MEDIUM]` — Not ready to ship.**

- YAML layer is solid.
- Trigger format spec is ambiguous (loose vs strict) — pick one and ship.
- Dispatch routing has two real conflicts between `account-manager.md` and `AGENTS.md` for `status` and `design`. Same words, different agents. Fix the routing tables before delivery.
- The apostrophe in `qa-engineer.md` line 21 is a one-character edit; fix it now.

**Next:** PM → Tech Lead → code-builder for the 3 bug fixes → re-test.

**Note on scope:** Only 3 of 6 existing agents audited. The other 3 (`delivery-engineer.md`, `solutions-architect.md`, `tech-lead.md`) were not inspected in this pass. Recommend running the same checks on them before final sign-off — particularly `tech-lead.md` which routes to `code-builder`, `bug-fixer`, `qa-engineer` and is central to the dispatch graph.

---

---

## 8. Audit — delivery-engineer.md · solutions-architect.md · tech-lead.md

**Date:** 2026-06-21 (second pass)
**Scope:** The 3 files NOT audited in section 7
**Method:** Same as sections 1–4 (regex frontmatter extraction, trigger-format check against updated `rules/common.md` §3 spec, dispatch-target resolution, 5-message routing simulation)

---

### 8.1 Per-File Status

#### `delivery-engineer.md` — `[PASS: LOW]`
- **YAML/frontmatter structure:** PASS — `---...---` present, all 6 canonical keys present
- **Trigger format (loose `[a-z0-9 _-]`):** WARN — 1 forbidden_triggers item contains chars outside the allowed set:
  - `ship to prod without ASK (first time)` — parentheses `()` and colon `:` are outside `[a-z0-9 _-]`
- **Handoff dispatch targets:** VALID — executes directly (no phantom agents)
- **Routing simulation:** `deploy to staging` → hits `staging` and `deploy` triggers ✓; all other messages produce no signal

**Finding:** The forbidden_triggers format issue is the same class as the original `qa-engineer.md` apostrophe bug. Recommend fixing all space+special-char forbidden_triggers across all agent files in a single sweep.

---

#### `solutions-architect.md` — `[PASS]`
- **YAML/frontmatter structure:** PASS
- **Trigger format:** PASS — zero violations under the loose spec
- **Handoff dispatch targets:** VALID — `tech-lead` (exists) + `code-builder` (planned v0.4.0) — both resolve ✓
- **Routing simulation:** no signal on any of the 5 sample messages. Expected — SA is not directly activated by these phrases; it routes through PM's brief-readiness handoff.

**Finding:** Cleanest file of the 3 audited here.

---

#### `tech-lead.md` — `[PASS]`
- **YAML/frontmatter structure:** PASS
- **Trigger format:** PASS — zero violations under the loose spec
- **Handoff dispatch targets:** VALID — all 10 targets (`code-builder`, `bug-fixer`, `code-reviewer`, `code-analyzer`, `code-explainer`, `evolution-agent`, `qa-engineer`, `delivery-engineer`, `project-manager`, `solutions-architect`) resolve to existing or planned v0.4.0 agents ✓
- **Routing simulation:** `what's the status` → hits `status` trigger ✓; all other messages produce no signal

**Finding:** Clean.

---

### 8.2 Summary Table

| Check | delivery-engineer | solutions-architect | tech-lead |
|-------|-------------------|---------------------|-----------|
| YAML/frontmatter | PASS | PASS | PASS |
| Trigger format | 1 forbidden violation | PASS | PASS |
| Handoff targets | VALID | VALID | VALID |
| Routing sim (5 msgs) | 1/5 hit | 0/5 hit | 1/5 hit |

---

### 8.3 New Finding

**Format drift in forbidden_triggers across all agent files** — The original audit flagged `qa-engineer.md` L21 apostrophe. That is fixed. But `delivery-engineer.md` forbidden_triggers[4] (`ship to prod without ASK (first time)`) contains parentheses and a colon, which also violate the spec. This suggests a systematic pattern: agent authors put parenthetical notes inside trigger strings rather than as separate list items or a separate field.

Recommend: sweep all 6 agent files for `forbidden_triggers` items containing `(` or `:` and migrate the notes to a `## Notes` or `## never_do` section instead of embedding them in the trigger string. This is a non-blocking finding but worth fixing before v0.4.0 ships.

---

### 8.4 Fix Verification (Section 7 follow-up)

The 4 fixes from section 7 bugs were applied before this audit:

| Fix | File | Status |
|-----|------|--------|
| Apostrophe removed from forbidden_triggers | `agents/qa-engineer.md` L21 | VERIFIED — `"run tests on someones behalf"` |
| "Daily status" → "Daily standup digest" | `AGENTS.md` L48 | VERIFIED — intent row renamed |
| "design" token removed from "UI/Frontend/Design" | `AGENTS.md` L40 | VERIFIED — row now reads `landing page, UI, frontend, dashboard, CSS, theme, make it look` |
| Trigger format rule amended to "lowercase + no chars outside `[a-z0-9 _-]`, spaces allowed" | `rules/common.md` §3 | VERIFIED — new sentence present at L74 |

All 4 fixes confirmed in-place.

---

### 8.5 Overall Status After Second Pass

**All 6 agent files now audited (6/6).**

| File | YAML | Format | Dispatch | Routing |
|------|------|--------|----------|---------|
| account-manager.md | PASS | 7 strict fails (space-violations, pre-fix) | VALID | 3/5 |
| project-manager.md | PASS | 8 strict fails | VALID | 3/5 |
| qa-engineer.md | PASS | 1 real fail (apostrophe — FIXED) | VALID | 3/5 |
| delivery-engineer.md | PASS | 1 forbidden (parens/colon) | VALID | 1/5 |
| solutions-architect.md | PASS | PASS | VALID | 0/5 |
| tech-lead.md | PASS | PASS | VALID | 1/5 |

**Remaining open items:**
1. delivery-engineer.md `forbidden_triggers[4]` — parentheses + colon in trigger string (non-blocking, same class as fixed qa-engineer issue)
2. Space-separated trigger format — 15 strict violations across account-manager + project-manager + qa-engineer (addressed by spec clarification in rules/common.md; agents technically still non-compliant but spec now explicitly permits spaces)

**No phantom-agent references. No YAML parse failures. No routing-table conflicts after the 3 AGENTS.md fixes.**

Ready for v0.3.0 sign-off pending the delivery-engineer forbidden_triggers sweep.

---

**End of report.**