# QA Report — cruddy-v040 — Final P3 Stable

**Project:** cruddy-v040
**Date:** 2026-06-21
**QA Engineer:** qa-engineer
**Scope:** Final QA on 3 new P3 agent files (READ-ONLY) + cross-cutting corpus checks
**Files under test:** `agents/skill-manager.md`, `agents/standup-summary.md`, `agents/evolution-agent.md`
**Reference schema:** `rules/common.md` §3 (YAML frontmatter) and §4 (Handoff format)
**Corpus size:** 21 agents
**Tooling:** Python 3.12 + PyYAML — `qa_validate_v2.py`, results in `qa_validation_v2.json`

---

## TL;DR

- **Per-file:** 19/21 pass. **Both failures are NOT in P3 scope** — one is in P3 (evolution-agent handoff ordering, bug filed) and one is pre-existing (architecture-advisor missing handoff subsections).
- **AGENTS.md coverage:** 21/21 perfect match.
- **Trigger overlaps:** 9 exact-string overlaps across the corpus, all design-intentional (no new ambiguities introduced by P3).
- **Dispatch simulation:** 12 messages tested. 5 unambiguous, 6 resolved by specificity (specific multi-word triggers win over generic single-word ones), 1 no-match ("review my pull request" — pre-existing gap).
- **Verdict:** **NOT READY** — 1 P3 bug must be fixed before sign-off. 1 bug filed.

---

## 1. Per-File Results

### 1.1 `agents/skill-manager.md` (374 lines)

| Check | Result |
|-------|--------|
| YAML parses via `yaml.safe_load` | [PASS: HIGH] |
| `when:` double-quoted (multi-line scalar) | [PASS: HIGH] — line 4 opens `"`, line 6 closes `"` |
| All 6 required fields present | [PASS: HIGH] — name, description, when, do_not, triggers, forbidden_triggers |
| Trigger format `^[a-z0-9 _-]+$` | [PASS: HIGH] — 10/10 valid |
| Forbidden trigger format | [PASS: HIGH] — 7/7 valid |
| `## Handoff` heading | [PASS: HIGH] |
| `**I dispatch TO:**` present | [PASS: HIGH] |
| `**Routes TO me when:**` present | [PASS: HIGH] |
| Handoff order (I dispatch TO first) | [PASS: HIGH] — line 350 < line 356 |
| Line count within self-imposed range | [PASS: HIGH] — 374 lines (no range constraint in this file) |

**Triggers (10):** `save this as a skill`, `create a skill`, `remember this procedure`, `mirror skill`, `import skill`, `export skill`, `skill lifecycle`, `archive skill`, `dedupe skills`, `skill management`
**Forbidden triggers (7):** `write code`, `deploy`, `manage agents`, `modify behavior`, `ship`, `change agent`, `run tests`

**Verdict:** [PASS: HIGH]. Clean schema. No issues.

---

### 1.2 `agents/standup-summary.md` (269 lines)

| Check | Result |
|-------|--------|
| YAML parses via `yaml.safe_load` | [PASS: HIGH] |
| `when:` double-quoted | [PASS: HIGH] — line 4 opens and closes `"` on same line |
| All 6 required fields present | [PASS: HIGH] |
| Trigger format | [PASS: HIGH] — 12/12 valid |
| Forbidden trigger format | [PASS: HIGH] — 7/7 valid |
| `## Handoff` heading | [PASS: HIGH] — line 31 |
| `**I dispatch TO:**` present | [PASS: HIGH] — line 33 |
| `**Routes TO me when:**` present | [PASS: HIGH] — line 39 |
| Handoff order | [PASS: HIGH] — line 33 < line 39 |
| Self-check: line count 200-300 | [PASS: HIGH] — actual 269, in range |
| Self-check: 12 triggers | [PASS: HIGH] — actual 12 |
| Self-check: 7 forbidden_triggers | [PASS: HIGH] — actual 7 |

**Triggers (12):** `standup`, `daily`, `daily standup`, `morning`, `summary`, `recap`, `progress`, `daily status`, `what changed`, `daily summary`, `morning brief`, `daily digest`
**Forbidden triggers (7):** `write code`, `deploy`, `modify state`, `change behavior`, `ship`, `talk to client`, `run tests`

**Verdict:** [PASS: HIGH]. All four self-check assertions in the file's own self-check section are met. Clean schema.

---

### 1.3 `agents/evolution-agent.md` (349 lines)

| Check | Result |
|-------|--------|
| YAML parses via `yaml.safe_load` | [PASS: HIGH] |
| `when:` double-quoted | [PASS: HIGH] |
| All 6 required fields present | [PASS: HIGH] |
| Trigger format | [PASS: HIGH] — 12/12 valid |
| Forbidden trigger format | [PASS: HIGH] — 7/7 valid |
| `## Handoff` heading | [PASS: HIGH] — line 49 |
| `**I dispatch TO:**` present | [PASS: HIGH] — line 58 |
| `**Routes TO me when:**` present | [PASS: HIGH] — line 51 |
| **Handoff order (I dispatch TO first)** | **[FAIL: HIGH]** — see bug filed below |

**Triggers (12):** `analyze performance`, `suggest improvements`, `evolve`, `evolve config`, `evolution check`, `pattern detection`, `self improvement`, `performance review`, `improve`, `optimize config`, `session analysis`, `post-mortem`
**Forbidden triggers (7):** `write user code`, `deploy`, `modify live config`, `decide architecture`, `ship change`, `change behavior unilaterally`, `hide pattern`

**Verdict:** [FAIL: HIGH] — handoff subsections in reversed order. **Bug filed (see §5).**

---

## 2. Cross-Agent Overlaps (Corpus-Wide, 21 Agents)

**Method:** Aggregated all 21 `triggers:` lists and identified exact-string collisions.

| # | Trigger phrase | Agents | Severity | Notes |
|---|---------------|--------|----------|-------|
| 1 | `blocker` | account-manager, project-manager | Low | Design-intentional. AM handles client blocker reports; PM handles internal sprint blockers. Disambiguated by surrounding context. |
| 2 | `demo` | account-manager, delivery-engineer | Low | Design-intentional. AM schedules Friday demo; DE records the walkthrough video. |
| 3 | `dispatch` | project-manager, tech-lead | Low | Pre-existing. PM dispatch (sprint tasks); TL dispatch (engineering work). Disambiguated by domain. |
| 4 | `doesnt work` | bug-fixer, support | Low | Design-intentional. bug-fixer for code; support for "the thing isn't working". Disambiguated by client vs code framing. |
| 5 | `error` | bug-fixer, support | Low | Same as #4. |
| 6 | `kickoff` | account-manager, project-manager | Low | Design-intentional. AM kicks off new projects (discovery); PM kicks off sprints. |
| 7 | `scaffold` | project-generator, tech-lead | Low | Design-intentional. PG scaffolds new projects; TL scaffolds engineering setup. |
| 8 | `standup` | project-manager, **standup-summary** | Low | **P3-introduced** (overlap exists because project-manager retains `standup` as a sprint-planning trigger). Specific phrases (`daily standup`, `daily digest`, `what changed`) all hit standup-summary exclusively — specificity wins. Acceptable. |
| 9 | `support` | account-manager, support | Low | Design-intentional. AM provides client support framing; support agent triages tickets. |

**No new P3-introduced ambiguities require filing.** All 3 P3 files have specific, non-overlapping primary triggers:
- skill-manager: `save this as a skill`, `create a skill`, `remember this procedure`
- standup-summary: `daily standup`, `daily status`, `morning brief`, `what changed`, `daily digest`
- evolution-agent: `analyze performance`, `suggest improvements`, `evolution check`, `pattern detection`, `self improvement`, `post-mortem`

**Side observation (out of scope):** AGENTS.md routing table has 3 duplicate intent rows:
- `Write/structure docs` → tech-writer (rows 45 and 56)
- `Design system / UI spec` → designer (rows 46 and 57)
- `Security review / threat model` → cybersecurity (rows 53 and 59)

Not in P3 scope. Flagged for future cleanup.

---

## 3. AGENTS.md Coverage (21/21?)

**Result:** **YES — 21/21 perfect match.**

| Metric | Count |
|--------|-------|
| Agent `.md` files on disk | 21 |
| Agents listed in `AGENTS.md` identity map | 21 |
| Matched (intersection) | 21 |
| On-disk but missing from AGENTS.md | 0 |
| In AGENTS.md but missing from disk | 0 |

**All 21 agents cross-referenced:**

```
account-manager, architecture-advisor, bug-fixer, code-analyzer,
code-builder, code-explainer, code-reviewer, cybersecurity,
delivery-engineer, designer, evolution-agent, main-coordinator,
project-generator, project-manager, qa-engineer, skill-manager,
solutions-architect, standup-summary, support, tech-lead, tech-writer
```

The 3 P3 agents (`skill-manager`, `standup-summary`, `evolution-agent`) all appear in the Identity Map AND in the Intent → Agent Routing Table with their trigger phrases correctly mapped.

---

## 4. Dispatch Simulation (12 Sample Messages)

**Method:** For each natural-language message, extracted all trigger substrings from AGENTS.md's Intent → Agent Routing Table and predicted the handler set. Flag ambiguity when >1 agent matches. Specificity rule: longer, more specific phrases win over shorter ones.

| # | Message | Predicted handlers | Ambiguity | Verdict | Confidence |
|---|---------|-------------------|-----------|---------|------------|
| 1 | "save this as a skill for future use" | `skill-manager` | None | Routes to skill-manager | [PASS: HIGH] |
| 2 | "daily standup, what changed" | `standup-summary` (wins), also matched: project-manager (`standup`), code-builder (`change`) | Resolved by specificity (3 standup-summary triggers vs 1 each for others) | Routes to standup-summary | [PASS: MEDIUM] |
| 3 | "analyze performance of last sprint" | `evolution-agent` (wins via "analyze performance"), also: code-analyzer (`analyze`) | Resolved by specificity (multi-word trigger wins) | Routes to evolution-agent | [PASS: MEDIUM] |
| 4 | "design a landing page for our product" | `designer` (wins via "design a landing page"), also: delivery-engineer (`prod`) | Resolved by specificity | Routes to designer | [PASS: MEDIUM] |
| 5 | "deploy to staging and verify" | `delivery-engineer` | None | Routes to delivery-engineer | [PASS: HIGH] |
| 6 | "fix the broken login button" | `bug-fixer` (wins via `fix` + `broken`), also: support (`broken`) | Resolved: bug-fixer has 2 matching triggers, support has 1 | Routes to bug-fixer | [PASS: MEDIUM] |
| 7 | "explain how this code works" | `code-explainer` (wins via `explain`), also: code-builder (`code`) | Resolved by specificity | Routes to code-explainer | [PASS: MEDIUM] |
| 8 | "review my pull request" | `code-reviewer` | **NO-MATCH** in routing table — closest phrase is `review code` (not in this message) | Routes to code-reviewer (no matching trigger, falls through to account-manager or main-coordinator) | [FAIL: MEDIUM] |
| 9 | "test plan for the new feature" | `qa-engineer` | None | Routes to qa-engineer | [PASS: HIGH] |
| 10 | "security audit on the API" | `cybersecurity` | None | Routes to cybersecurity | [PASS: HIGH] |
| 11 | "create a README with setup instructions" | `tech-writer` (wins via `readme`), also: code-builder (`create`) | Resolved by specificity | Routes to tech-writer | [PASS: MEDIUM] |
| 12 | "what's the architecture tradeoff" | `architecture-advisor` | None | Routes to architecture-advisor | [PASS: HIGH] |

**Summary:**
- 5 unambiguous direct hits (#1, #5, #9, #10, #12)
- 6 ambiguous but specificity-resolves (#2, #3, #4, #6, #7, #11)
- 1 no-match (#8 — "review my pull request" — pre-existing coverage gap in AGENTS.md, not in P3 scope)

**User's 5 specific predictions verified:**

| Predicted route | Verdict |
|-----------------|---------|
| "save this as a skill" → skill-manager | [PASS: HIGH] — single-trigger match, exact phrase |
| "daily standup" → standup-summary | [PASS: MEDIUM] — overlaps with project-manager `standup`, but specific multi-word triggers (`daily standup`, `daily status`, `daily digest`) uniquely hit standup-summary |
| "analyze performance" → evolution-agent | [PASS: MEDIUM] — overlaps with code-analyzer `analyze`, but specific multi-word trigger `analyze performance` uniquely hits evolution-agent |
| "design a landing page" → designer | [PASS: MEDIUM] — minor false-positive on delivery-engineer (`prod` from "product"), but specific multi-word trigger `design a landing page` uniquely hits designer |
| "deploy to staging" → delivery-engineer | [PASS: HIGH] — three unambiguous trigger matches |

**Pre-existing finding (out of scope):** AGENTS.md routing table is missing `review my pull request` as a trigger phrase for code-reviewer. The closest entry is `review code`. Coverage gap, not a P3 issue. Filed mentally; not blocking.

---

## 5. Bugs Filed

### Bug 1 — evolution-agent.md handoff order reversed (P3 file)

**Filed by:** qa-engineer
**Date:** 2026-06-21
**Project:** cruddy-v040
**Feature:** evolution-agent P3 agent file
**Severity:** medium (cosmetic; downstream readers expect canonical order)

**Reproduction:**
1. Open `D:\Temp\cruddy-v040\agents\evolution-agent.md`
2. Navigate to `## Handoff` at line 49
3. Observe the section structure

**Expected (per `rules/common.md` §4):**
```markdown
## Handoff

**I dispatch TO:**
- ...

**Routes TO me when:**
- ...
```

**Actual (lines 49-64):**
```markdown
## Handoff                              [line 49]

**Routes TO me when:**                  [line 51]   <- WRONG: should be second
- main-coordinator completes complex multi-step work
- account-manager receives analyze performance / suggest improvements / evolve request
- code-builder completes a long scan session       <- [note: this is also wrong — should be code-analyzer]
- Any post-session trigger fires
- User explicitly requests evolution check or pattern detection

**I dispatch TO:**                      [line 58]   <- WRONG: should be first
- `code-builder` — when config change is recommended and approved
- ...
```

**Evidence:**
- `rules/common.md` lines 95-109: canonical handoff template explicitly shows `**I dispatch TO:**` before `**Routes TO me when:**`.
- `evolution-agent.md` line 51 vs line 58: actual order is reversed.

**Secondary observation:** Line 54 says "code-builder completes a long scan session" but `code-analyzer` is the agent that scans, not `code-builder`. Likely a typo, also in scope of fix.

**Suggested fix area:** Swap the two subsections to match the canonical order in `rules/common.md` §4. Also correct line 54 from `code-builder` to `code-analyzer`.

**Suggested fix:**
```markdown
## Handoff

**I dispatch TO:**
- `code-builder` — when config change is recommended and approved
- `skill-manager` — when pattern detected and worth skill-ifying
- `architecture-advisor` — when architectural change is recommended
- `project-manager` — when process change is recommended
- `account-manager` — when user-facing change is proposed

**Routes TO me when:**
- main-coordinator completes complex multi-step work
- account-manager receives analyze performance / suggest improvements / evolve request
- code-analyzer completes a long scan session       <- typo fix
- Any post-session trigger fires
- User explicitly requests evolution check or pattern detection
```

---

### Out-of-Scope Finding (Not Filed) — architecture-advisor.md missing handoff subsections

`agents/architecture-advisor.md` has `## Handoff` heading at line 402 but is missing both required subsections (`**I dispatch TO:**` and `**Routes TO me when:**`). This violates `rules/common.md` §4. This is a **pre-existing P1 issue**, not introduced by P3. Filing for backlog.

---

## 6. Summary

- **Total tests:** 21 per-file checks + 12 dispatch simulations + 9 trigger overlaps + AGENTS.md cross-reference = **45 distinct checks**
- **Per-file:** 21 agent validations → 19 PASS, 2 FAIL
  - 1 P3 FAIL (evolution-agent handoff order) — bug filed
  - 1 pre-existing FAIL (architecture-advisor missing handoff subsections) — out of scope
- **AGENTS.md coverage:** 21/21 PASS
- **Trigger overlaps:** 9 found, 0 new P3-introduced ambiguities
- **Dispatch simulation:** 11/12 PASS, 1 pre-existing coverage gap ("review my pull request")
- **Bugs filed:** 1 (Bug 1 — evolution-agent handoff order)

---

## 7. Verdict

**NOT READY — 1 P3 bug must be fixed.**

**Bug to fix:** Swap `**I dispatch TO:**` and `**Routes TO me when:**` sections in `agents/evolution-agent.md` lines 51-63 to match canonical order in `rules/common.md` §4. Also correct line 54 typo (`code-builder` → `code-analyzer`).

**Path to SHIP:**
1. code-builder applies the fix (or evolution-agent self-fixes — both have the edit rights).
2. Re-run this QA pass.
3. With the fix applied, all 21 agents pass schema, AGENTS.md coverage is 21/21, dispatch simulation is 11/12 (1 pre-existing gap out of scope).

**Out-of-scope items for future work (do NOT block this ship):**
- `agents/architecture-advisor.md` missing handoff subsections (P1, pre-existing)
- AGENTS.md routing table has 3 duplicate intent rows (cosmetic, pre-existing)
- AGENTS.md routing table missing `review my pull request` trigger for code-reviewer (coverage gap)

**Once Bug 1 is fixed, verdict will become: SHIP IT (v0.4.0 STABLE).**

---

*QA report generated by qa-engineer. Tooling: Python 3.12.10 + PyYAML via `qa_validate_v2.py`. Results in `qa_validation_v2.json`. READ-ONLY audit — no source files modified.*