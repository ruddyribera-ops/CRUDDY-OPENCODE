# QA Report — Beta — Agent Files Round 1 (4 files)

**Filed by:** QA Engineer
**Date:** 2026-06-21
**Scope:** READ-ONLY QA on 4 agent files in `D:\Temp\cruddy-v030\agents/`
- `code-builder.md`
- `bug-fixer.md`
- `main-coordinator.md`
- `code-analyzer.md`

**Spec source:** `rules/common.md` §3 (YAML frontmatter), §4 (handoff format); `account-manager.md` dispatch table; `AGENTS.md` routing table.

---

## 1. Final Line Counts

| File | User-stated | Actual (newline-inclusive) | Diff |
|---|---|---|---|
| code-builder.md | 319 | 320 | +1 (trailing newline) |
| bug-fixer.md | 207 | 208 | +1 (trailing newline) |
| main-coordinator.md | 317 | 318 | +1 (trailing newline) |
| code-analyzer.md | 282 | 283 | +1 (trailing newline) |

Discrepancy is mechanical (file ends with `\n`); Read tool reports content lines.

---

## 2. Per-File Results

### 2.1 code-builder.md — **FAIL** (handoff format)

| Check | Result | Evidence |
|---|---|---|
| YAML frontmatter parses | [PASS: HIGH] | yaml.safe_load OK |
| All 6 required fields present | [PASS: HIGH] | name, description, when, do_not, triggers (14), forbidden_triggers (8) |
| Trigger format (lowercase + `[a-z0-9 _-]`) | [PASS: HIGH] | All 14 triggers and 8 forbidden_triggers valid |
| `## Handoff` with `**I dispatch TO:**` and `**Routes TO me when:**` | **[FAIL: MEDIUM]** | Line 301 = `# HANDOFF` (H1, not H2); uses `## I Dispatch TO` and `## Routes TO Me` (H2 headings, not bold inline labels); content is a markdown table, not a bullet list. See Bug B1. |
| Dispatch TO references resolve | [PASS: HIGH] | bug-fixer ✓, qa-engineer ✓, code-reviewer (labeled v0.4.0) ✓, tech-writer (labeled v0.4.0) ✓ |
| Lines | 320 | |

### 2.2 bug-fixer.md — **PASS** (with one note)

| Check | Result | Evidence |
|---|---|---|
| YAML frontmatter parses | [PASS: HIGH] | yaml.safe_load OK |
| All 6 required fields present | [PASS: HIGH] | name, description, when, do_not, triggers (12), forbidden_triggers (7) |
| Trigger format | [PASS: HIGH] | All 12 triggers and 7 forbidden_triggers valid (incl. `arreglar`, `falla`, `doesnt work`, `stack trace`) |
| `## Handoff` with required subsections | [PASS: HIGH] | Line 194 = `## Handoff`; lines 196/202 use `**I dispatch TO:**` and `**Routes TO me when:**` exactly as required |
| Dispatch TO references resolve | [PASS: HIGH] | code-builder ✓, qa-engineer ✓, code-analyzer ✓, tech-lead ✓ |
| Lines | 208 | |

### 2.3 main-coordinator.md — **PASS** (with one note)

| Check | Result | Evidence |
|---|---|---|
| YAML frontmatter parses | [PASS: HIGH] | yaml.safe_load OK |
| All 6 required fields present | [PASS: HIGH] | name, description, when, do_not, triggers (8), forbidden_triggers (7) |
| Trigger format | [PASS: HIGH] | All 8 triggers and 7 forbidden_triggers valid |
| `## Handoff` with required subsections | [PASS: HIGH] | Line 286 = `## Handoff`; lines 288/300 use `**I dispatch TO:**` and `**Routes TO me when:**` exactly as required |
| Dispatch TO references resolve | [PASS: MEDIUM] | 7/10 in agents/ ✓; 3 reference non-existent agents without explicit `(v0.4.0)` label: `cybersecurity`, `designer`, `architecture-advisor`. These ARE listed in `AGENTS.md` identity map (planned 21). See Bug B7. |
| Lines | 318 | |

### 2.4 code-analyzer.md — **FAIL** (handoff subsection mismatch + style)

| Check | Result | Evidence |
|---|---|---|
| YAML frontmatter parses | [PASS: HIGH] | yaml.safe_load OK |
| All 6 required fields present | [PASS: HIGH] | name, description, when, do_not, triggers (11), forbidden_triggers (8) |
| Trigger format | [PASS: HIGH] | All 11 triggers and 8 forbidden_triggers valid (quoted and unquoted mixed; YAML-safe) |
| `## Handoff` with required subsections | **[FAIL: LOW]** | Line 267 = `## Handoff` ✓; line 269 = `**I dispatch TO:**` ✓; line 277 = `**I receive FROM:**` ✗ (should be `**Routes TO me when:**`). See Bug B2. |
| YAML style consistency | **[FAIL: LOW]** | Blank lines between trigger and forbidden_triggers items; the other 3 files use compact style. See Bug B3. |
| Dispatch TO references resolve | [PASS: MEDIUM] | tech-writer (v0.4.0) ✓, bug-fixer ✓, code-reviewer (v0.4.0) ✓, tech-lead ✓; `code-explainer` referenced without v0.4.0 label. See Bug B7. |
| Lines | 283 | |

---

## 3. Cross-Agent Trigger Overlap (all 10 agents)

Detection scanned all triggers across all 10 agent files. `delivery-engineer.md` failed YAML parse (pre-existing: `demo:` in description at column 173) — regex fallback used; it does not affect the 4 target files.

**Result: 6 overlaps found.**

| # | Trigger | Agents | Assessment | Severity |
|---|---|---|---|---|
| 1 | `status` | account-manager, project-manager, tech-lead | 3-way ambiguity. `account-manager.md` dispatch table does NOT list "status". `AGENTS.md` routing table sends it to `standup-summary` (not in agents/). No disambiguation. | **MEDIUM** — Bug B4 |
| 2 | `bug` | bug-fixer, qa-engineer | qa-engineer also has more specific `file-bug` and `write-test-plan`. Bare `bug` is redundant and could collide with bug-fixer's primary intent. | LOW — Bug B6 |
| 3 | `demo` | account-manager, delivery-engineer | Scopes differ (organize vs record). Acceptable by design. | LOW — INFO only |
| 4 | `dispatch` | project-manager, tech-lead | Scopes differ (PM task assignment vs engineering routing). Acceptable by design. | LOW — INFO only |
| 5 | `kickoff` | account-manager, project-manager | Scopes differ (new project vs sprint kickoff). Acceptable by design. | LOW — INFO only |
| 6 | `blocker` | account-manager, project-manager | Scopes differ (client vs internal). Acceptable by design. | LOW — INFO only |

**Forbidden-trigger overlap (informational):** 4 shared forbidden strings detected (`fix bug`, `write code`, `deploy`, `ship`) — all by design (negative disambiguation pushing work to canonical owners). NOT a defect.

---

## 4. Dispatch Simulation — 8 Sample Messages

Routing prediction uses `account-manager.md` mandatory dispatch table + `AGENTS.md` routing table. Trigger match = at least one phrase in the message is present in the predicted agent's `triggers` list.

| # | Message | Predicted Agent | Source of Prediction | Trigger Match | Notes |
|---|---|---|---|---|---|
| 1 | "fix this bug" | `bug-fixer` | AM table + AGENTS.md | ✓ (`fix`, `bug`) | Clean dispatch |
| 2 | "write a login function" | `code-builder` | AM table + AGENTS.md | ✓ (`write`) | Clean dispatch |
| 3 | "deploy to staging" | `delivery-engineer` | AM table + AGENTS.md | ✓ (`deploy`, `staging`) | Clean dispatch |
| 4 | "scan the codebase" | `code-analyzer` | AM table + AGENTS.md | ✓ (`scan`) | Clean dispatch |
| 5 | "what's the status" | `standup-summary` (per AGENTS.md) | AGENTS.md only — AM table silent; agent file not present | ✗ among existing agents; "status" matches 3 (AM/PM/tech-lead) | Routing conflict — Bug B4 |
| 6 | "design a landing page" | `designer` (AM) **vs** `code-builder` (AGENTS.md) | DISAGREEMENT between sources | ✗ for code-builder (no trigger match); ✓ for designer via AM table | Sources contradict — Bug B5 |
| 7 | "add a new feature" | `code-builder` | AM table + AGENTS.md | ✓ (`add`) | Clean dispatch |
| 8 | "the test is failing" | `qa-engineer` | AM table + AGENTS.md | ✓ (`test`) | Clean; "failing" alone is in no agent's triggers but context disambiguates |

**Score: 6/8 clean, 2/8 with routing problems.**

---

## 5. Bugs Filed

| ID | Severity | File(s) | Title |
|---|---|---|---|
| B1 | **MEDIUM** | code-builder.md | Handoff section format mismatch — uses `# HANDOFF` (H1) + `## I Dispatch TO`/`## Routes TO Me` (H2) + table; spec requires `## Handoff` (H2) + `**I dispatch TO:**` + `**Routes TO me when:**` per `rules/common.md` §4 |
| B2 | LOW | code-analyzer.md | Handoff "inbound" label mismatch — uses `**I receive FROM:**` instead of canonical `**Routes TO me when:**` |
| B3 | LOW | code-analyzer.md | YAML style inconsistency — blank lines between list items in `triggers` and `forbidden_triggers`; other 3 target files use compact style |
| B4 | **MEDIUM** | account-manager.md, project-manager.md, tech-lead.md, AGENTS.md | 3-way trigger overlap on "status" — no disambiguation; AM dispatch table silent; AGENTS.md routes to `standup-summary` (no agent file) |
| B5 | **MEDIUM** | account-manager.md, AGENTS.md | Routing table disagreement on `landing page` — AM says `designer`, AGENTS.md says `code-builder` |
| B6 | LOW | bug-fixer.md, qa-engineer.md | Bare `bug` trigger overlap — `qa-engineer` should rely on `file-bug` and `write-test-plan`; remove `bug` to avoid collision with bug-fixer's primary intent |
| B7 | LOW | main-coordinator.md, code-analyzer.md | References to non-existent agents lack `(v0.4.0)` label — `cybersecurity`, `designer`, `architecture-advisor` (main-coordinator); `code-explainer` (code-analyzer). Listed in `AGENTS.md` identity map but not explicitly annotated. |

---

## 6. Out-of-Scope Findings (not bugs against the 4 target files)

- `delivery-engineer.md` has a **pre-existing YAML parse error** — `description:` contains `: live URL` which YAML interprets as a mapping. Affects cross-agent overlap detection for that file only; used regex fallback. Recommend separate bug filing against `delivery-engineer.md` once in scope.

---

## 7. Verdict

**FAIL — NOT READY TO MERGE**

- Tests failed: 3 MEDIUM bugs (B1, B4, B5) + 4 LOW bugs (B2, B3, B6, B7)
- All 4 YAML frontmatters parse cleanly and contain all 6 required fields — schema layer is healthy.
- The defects are concentrated in two layers:
  1. **Handoff format conformance** (B1, B2) — code-builder.md and code-analyzer.md diverge from the canonical `## Handoff` template in `rules/common.md` §4.
  2. **Cross-agent routing integrity** (B4, B5, B6, B7) — trigger overlaps and conflicting routing tables create dispatch ambiguity.

### Required to ship

1. Fix B1 — restructure code-builder.md Handoff to match `rules/common.md` §4 template.
2. Fix B2 — rename `**I receive FROM:**` to `**Routes TO me when:**` in code-analyzer.md.
3. Fix B3 — remove blank lines in code-analyzer.md trigger lists for style consistency.
4. Fix B4 — disambiguate `status` (either move it to a non-conflicting phrase, or document primary owner; address the missing `standup-summary` agent file or remove the AGENTS.md routing claim).
5. Fix B5 — resolve AM vs AGENTS.md disagreement on `landing page` (decide: code-builder or designer; update both sources to match).
6. Fix B6 — remove bare `bug` from qa-engineer triggers; keep `file-bug` and `write-test-plan`.
7. Fix B7 — annotate the planned-v0.4.0 references in main-coordinator.md and code-analyzer.md with `(v0.4.0)` to match the convention used in code-builder.md and code-analyzer.md's own tech-writer/code-reviewer references.

### Next step

PM → Tech Lead → `code-builder` to apply fixes → re-test.