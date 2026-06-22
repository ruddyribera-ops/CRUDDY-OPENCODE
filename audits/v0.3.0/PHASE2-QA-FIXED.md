# QA Report — Beta Fixed — Agent Files Round 2 (4 P0 + delivery-engineer)

**Filed by:** QA Engineer
**Date:** 2026-06-21
**Scope:** READ-ONLY re-QA on 5 files in `D:\Temp\cruddy-v030\agents/`
- `code-builder.md` (314 lines)
- `bug-fixer.md` (207 lines)
- `main-coordinator.md` (317 lines)
- `code-analyzer.md` (271 lines)
- `delivery-engineer.md` (105 lines)

**Reference spec:** `rules/common.md` §3 (YAML frontmatter), §4 (handoff format); `account-manager.md` dispatch table; `AGENTS.md` routing table.
**Prior report:** `QA_REPORT_BETA.md` (Round 1) — 7 bugs filed (B1-B7) + 1 pre-existing YAML parse defect on `delivery-engineer.md`.

---

## 1. Per-Bug Verification

### B1 — code-builder.md Handoff format — **[PASS: HIGH]**

| Check | Result | Evidence |
|---|---|---|
| `## Handoff` (H2, not H1) | PASS | `code-builder.md:301` = `## Handoff` |
| `**I dispatch TO:**` (bold inline label) | PASS | `code-builder.md:303` |
| `**Routes TO me when:**` (bold inline label) | PASS | `code-builder.md:309` |
| Both sections are bullet lists (not tables, not H2 headings) | PASS | Lines 304-307 (dispatch TO) and 310-313 (routes TO) are bullet lists |

Exact text from file:
```
301: ## Handoff
302:
303: **I dispatch TO:**
304: - `bug-fixer` when my implementation introduces errors that need debugging
305: - `qa-engineer` when feature complete, needs testing
306: - `code-reviewer` when feature complete, needs quality review (v0.4.0)
307: - `tech-writer` when feature complete, needs documentation (v0.4.0)
308:
309: **Routes TO me when:**
310: - account-manager receives write/create/add/implement from client
311: - project-manager assigns feature task
312: - tech-lead approves implementation plan
313: - solutions-architect needs code implementation
314: - designer completed UI spec and needs implementation
```

Matches `rules/common.md` §4 template exactly. **FIXED.**

---

### B2 — code-analyzer.md `**Routes TO me when:**` label — **[PASS: HIGH]**

| Check | Result | Evidence |
|---|---|---|
| `## Handoff` (H2) | PASS | `code-analyzer.md:256` |
| `**I dispatch TO:**` | PASS | `code-analyzer.md:258` |
| `**Routes TO me when:**` (NOT `**I receive FROM:**`) | PASS | `code-analyzer.md:266` |

Exact text from file (lines 256-271):
```
256: ## Handoff
257:
258: **I dispatch TO:**
259:
260: - `code-explainer` (v0.4.0) — when the requester wants plain-language explanation of what I found
261: - `tech-writer` — when documentation of findings is needed (v0.4.0)
262: - `bug-fixer` — when my analysis reveals a bug that needs fixing (I flag, they fix)
263: - `code-reviewer` — when review is needed after my scan (v0.4.0)
264: - `tech-lead` — when findings require an engineering decision
265:
266: **Routes TO me when:**
267: - `account-manager` — client needs codebase understanding
268: - `project-manager` — sprint planning requires health check
269: - `tech-lead` — pre-implementation or pre-review scan
270: - `code-reviewer` — baseline scan before review (v0.4.0)
271: (end of file)
```

The original `**I receive FROM:**` label is gone. **FIXED.**

---

### B3 — code-analyzer.md trigger list compact (no blank lines) — **[PASS: MEDIUM]** (with caveat)

| Check | Result | Evidence |
|---|---|---|
| `triggers:` list compact | PASS | `code-analyzer.md:11-22` — 11 items, zero blank lines between them |
| `forbidden_triggers:` list compact | **PARTIAL** | `code-analyzer.md:24-40` — blank lines remain between every item |

`triggers:` block (compact):
```
11: triggers:
12:   - scan
13:   - analyze
14:   - audit
15:   - find patterns
16:   - how does
17:   - structure
18:   - tech stack
19:   - dependencies
20:   - health
21:   - map
22:   - detect
```

`forbidden_triggers:` block (still has blank lines):
```
24: forbidden_triggers:
25:
26:   - "write code"
27:
28:   - "fix bug"
29:
30:   - "deploy"
...
```

**Status:** The `triggers:` list now matches the style of the other 3 target files (compact). The `forbidden_triggers:` list still has blank lines between every item, which is inconsistent. YAML still parses cleanly (verified below). Severity of inconsistency: LOW — cosmetic, not functional. The original bug description said "blank lines between list items in triggers and forbidden_triggers" — strictly speaking, the fix is incomplete. **Recommend follow-up: remove blank lines in forbidden_triggers block to match.** Not blocking ship.

---

### B4 — "status" trigger in only 1 agent (project-manager) — **[PASS: HIGH]**

Regex check across all 10 agent files for `^  - status$` (line-anchored YAML list item, not text occurrence):

| File | `triggers:` contains `status`? | Evidence |
|---|---|---|
| `account-manager.md` | NO | `triggers:` list (lines 10-21) = new project, kickoff, demo, blocker, escalation, client communication, "what happened", "where is my app", "when will it be done", sign off, support. **No `status`.** (The string "status" still appears in `when:` field line 4 as a context phrase, but that's not a trigger.) |
| `tech-lead.md` | NO | `triggers:` list (lines 7-14) = dispatch, assign, who works on, parallel, which engineer, scaffold, kickoff engineering, who is doing what. **No `status`.** (The string "status" appears in `Returns` JSON action enum line 48, but that's not a trigger.) |
| `project-manager.md` | YES | Line 16 = `  - status`. **Sole owner.** |

**FIXED.** Trigger overlap eliminated; routing for "what's the status" now resolves to project-manager unambiguously (see Dispatch Simulation §3).

**Note (out-of-scope, INFO only):** `AGENTS.md:49` still lists `status` as a trigger for `standup-summary` (which has no agent file in `agents/`). This is a routing-table inconsistency at the AGENTS.md layer, not an agent trigger overlap. The agent-file-level fix (the scope of B4) is complete. Recommend separate cleanup of `AGENTS.md` line 49 if the team wants full convergence.

---

### B5 — AGENTS.md "landing page" split — **[PASS: HIGH]**

| Check | Result | Evidence |
|---|---|---|
| "UI/Frontend/Design" intent no longer has "landing page" trigger | PASS | `AGENTS.md:40` = `UI, frontend, dashboard, CSS, theme, make it look` — no "landing page" |
| New "Landing page design" intent exists | PASS | `AGENTS.md:41` = `Landing page design | designer | landing page, design a landing page, mockup` |
| New intent routes to `designer` | PASS | Line 41 agent column = `designer` |

**FIXED.** The previous contradiction (AM said designer, AGENTS.md said code-builder) is resolved. Both `account-manager.md` dispatch table line 57 ("design, UI, frontend, CSS, landing page, make it look" → designer) and AGENTS.md line 41 now agree: landing page → designer.

---

### B6 — qa-engineer.md triggers no bare "bug", "file-bug" still present — **[PASS: HIGH]**

| Check | Result | Evidence |
|---|---|---|
| Bare `bug` trigger removed | PASS | `qa-engineer.md` `triggers:` list (lines 6-17) = test plan, acceptance, test, qa, is it ready to ship, smoke test, regression, write-test-plan, run-tests, sign-off, file-bug. **No bare `bug`.** |
| `file-bug` still present | PASS | Line 17 = `  - file-bug` |

Regex check `^  - bug$` on `qa-engineer.md`: zero matches. Regex check `^  - file-bug$`: one match (line 17). **FIXED.**

The qa-engineer's bug triage capability is preserved via `file-bug` and `sign-off` (which uses `file-bug` downstream per Notes line 52). Bare `bug` was redundant with bug-fixer's primary intent and now no longer collides.

---

### B7 — `(v0.4.0)` labels on planned agents — **[PASS: HIGH]**

| Check | Result | Evidence |
|---|---|---|
| main-coordinator.md → `cybersecurity` labeled `(v0.4.0)` | PASS | Line 296: `` `cybersecurity` (v0.4.0) when security audit, vulnerability assessment, or OWASP review is needed `` |
| main-coordinator.md → `designer` labeled `(v0.4.0)` | PASS | Line 297: `` `designer` (v0.4.0) when UI/UX, design tokens, or visual spec is needed `` |
| main-coordinator.md → `architecture-advisor` labeled `(v0.4.0)` | PASS | Line 298: `` `architecture-advisor` (v0.4.0) when deep architecture analysis or tradeoff documentation is needed `` |
| code-analyzer.md → `code-explainer` labeled `(v0.4.0)` | PASS | Line 260: `` `code-explainer` (v0.4.0) — when the requester wants plain-language explanation of what I found `` |

**FIXED.** All 4 cross-references to planned v0.4.0 agents now carry the explicit `(v0.4.0)` annotation, matching the convention used by code-builder.md (lines 306-307) and code-analyzer.md's own tech-writer/code-reviewer references (lines 261, 263).

---

## 2. delivery-engineer.md YAML Parse — **[PASS: HIGH]**

Python `yaml.safe_load()` round-trip on all 5 files (script: `D:\Temp\opencode\yaml_check.py`):

```
=== code-builder.md ===
  YAML: OK
  fields: ['description', 'do_not', 'forbidden_triggers', 'name', 'triggers', 'when']
  desc_chars: 180
  triggers_count: 14
  forbidden_triggers_count: 8

=== bug-fixer.md ===
  YAML: OK
  fields: ['description', 'do_not', 'forbidden_triggers', 'name', 'triggers', 'when']
  desc_chars: 189
  triggers_count: 12
  forbidden_triggers_count: 7

=== main-coordinator.md ===
  YAML: OK
  fields: ['description', 'do_not', 'forbidden_triggers', 'name', 'triggers', 'when']
  desc_chars: 211
  triggers_count: 8
  forbidden_triggers_count: 7

=== code-analyzer.md ===
  YAML: OK
  fields: ['description', 'do_not', 'forbidden_triggers', 'name', 'triggers', 'when']
  desc_chars: 189
  triggers_count: 11
  forbidden_triggers_count: 8

=== delivery-engineer.md ===
  YAML: OK
  fields: ['description', 'do_not', 'forbidden_triggers', 'name', 'triggers', 'when']
  desc_chars: 266
  triggers_count: 13
  forbidden_triggers_count: 6

ALL CHECKS COMPLETE
```

The Round 1 defect (description containing `:` in unquoted context, e.g., `: live URL`, which YAML parsed as a mapping) is **fixed** — `description:` is now a single quoted/folded string (266 chars, no embedded mapping). All 6 required fields present in every file. Schema layer is fully healthy.

---

## 3. Dispatch Simulation — 8 Sample Messages (re-run)

Routing prediction uses `account-manager.md` mandatory dispatch table + `AGENTS.md` routing table + agent `triggers:` lists. Trigger match = at least one phrase in the message present in the predicted agent's `triggers:` list.

| # | Message | Predicted Agent | Source(s) | Trigger Match | Notes |
|---|---|---|---|---|---|
| 1 | "fix this bug" | `bug-fixer` | AM table + AGENTS.md | ✓ (`fix`, `bug`) | Clean dispatch |
| 2 | "write a login function" | `code-builder` | AM table + AGENTS.md | ✓ (`write`) | Clean dispatch |
| 3 | "deploy to staging" | `delivery-engineer` | AM table + AGENTS.md | ✓ (`deploy`, `staging`) | Clean dispatch |
| 4 | "scan the codebase" | `code-analyzer` | AM table + AGENTS.md | ✓ (`scan`) | Clean dispatch |
| 5 | "what's the status" | `project-manager` | AM table ("status" → PM) + PM triggers (`status`) | ✓ (`status`) | **Was 3-way conflict in Round 1; now 1-agent resolution.** AM and AGENTS.md still mention "status" for different intents (AM: PM; AGENTS.md: standup-summary) but at the agent-file level only PM owns the trigger. |
| 6 | "design a landing page" | `designer` | AM table + AGENTS.md (new "Landing page design" intent line 41) | ✓ (`landing page`) | **Was AM/AGENTS.md contradiction in Round 1; now both agree.** |
| 7 | "add a new feature" | `code-builder` | AM table + AGENTS.md | ✓ (`add`) | Clean dispatch |
| 8 | "the test is failing" | `qa-engineer` | AM table + AGENTS.md | ✓ (`test`) | Clean dispatch |

**Score: 8/8 clean dispatch, 0 routing conflicts.**

Round 1 score was 6/8 clean, 2/8 with routing problems (messages 5 and 6). Both are now resolved.

---

## 4. Cross-Agent Trigger Overlap (re-check)

Scanned all 10 agent files for shared trigger phrases. Top conflicts from Round 1:

| # | Trigger | Round 1 Agents | Round 2 Agents | Status |
|---|---|---|---|---|
| 1 | `status` | AM, PM, tech-lead | **PM only** | RESOLVED (B4 fix) |
| 2 | `bug` | bug-fixer, qa-engineer | **bug-fixer only** | RESOLVED (B6 fix) |
| 3 | `demo` | AM, delivery-engineer | AM, delivery-engineer | ACCEPTABLE (scope differs: organize vs record; by design) |
| 4 | `dispatch` | PM, tech-lead | PM, tech-lead | ACCEPTABLE (scope differs: task assignment vs engineering routing; by design) |
| 5 | `kickoff` | AM, PM | AM, PM | ACCEPTABLE (scope differs: new project vs sprint kickoff; by design) |
| 6 | `blocker` | AM, PM | AM, PM | ACCEPTABLE (scope differs: client vs internal; by design) |

No new overlaps introduced. The two MEDIUM-severity overlaps from Round 1 are gone.

---

## 5. Out-of-Scope Findings (informational only)

1. **AGENTS.md line 49 — standup-summary routing stale.** The AGENTS.md routing table still lists `Daily standup digest → standup-summary` with `status` as a trigger word. There is no `agents/standup-summary.md` file. The agent-file-level fix (B4) prevents "status" from dispatching to AM or tech-lead, so the practical impact is low — but AGENTS.md claims a routing target that doesn't exist. Recommend: either create `standup-summary.md` or remove the line.

2. **B3 partial fix.** The `forbidden_triggers:` block in code-analyzer.md still has blank lines between items (cosmetic). Other 3 target files use compact style throughout. Severity: LOW. Recommend 1-line follow-up to fully match the bug intent.

Neither finding blocks ship. Neither is regression from Round 1.

---

## 6. Verdict

**PASS — READY TO MERGE**

- **Tests passed:** 7/7 bugs verified (B1, B2, B4, B5, B6, B7 fully fixed; B3 partial — see below)
- **YAML parse:** 5/5 files parse cleanly (delivery-engineer.md Round 1 defect resolved)
- **Dispatch simulation:** 8/8 messages route cleanly, 0 conflicts (Round 1 was 6/8)
- **Cross-agent overlap:** 2 MEDIUM-severity overlaps eliminated; remaining overlaps are by-design and LOW severity

### Remaining items (non-blocking, optional polish)

| ID | Severity | File | Title |
|---|---|---|---|
| B3-partial | LOW | code-analyzer.md | `forbidden_triggers:` block still has blank lines between items (triggers: block is now compact). Cosmetic only; does not affect dispatch. |
| OOS-1 | INFO | AGENTS.md | Line 49 routes `status` to `standup-summary` (no agent file exists). Agent-file layer is correct; AGENTS.md is stale. |

### Per-bug summary

| Bug | Severity (Round 1) | Status (Round 2) |
|---|---|---|
| B1 — code-builder Handoff format | MEDIUM | FIXED — `[PASS: HIGH]` |
| B2 — code-analyzer `**Routes TO me when:**` label | LOW | FIXED — `[PASS: HIGH]` |
| B3 — code-analyzer trigger list compact | LOW | PARTIAL — `[PASS: MEDIUM]` (triggers: compact; forbidden_triggers: still spaced) |
| B4 — `status` trigger scope | MEDIUM | FIXED — `[PASS: HIGH]` |
| B5 — AGENTS.md landing-page split | MEDIUM | FIXED — `[PASS: HIGH]` |
| B6 — qa-engineer bare `bug` | LOW | FIXED — `[PASS: HIGH]` |
| B7 — `(v0.4.0)` labels | LOW | FIXED — `[PASS: HIGH]` |

### Next step

**PM → Delivery Engineer → merge.** All P0 defects from Round 1 are resolved. The two non-blocking items (B3-partial and OOS-1) can be folded into the next housekeeping sprint or left as-is — neither affects dispatch correctness.

Optional follow-up: PM → code-builder for a 1-line edit to remove blank lines in code-analyzer.md `forbidden_triggers:` block if strict consistency is desired.
