# Architect Design — Project 2A (4 Specialist Agents)

**Created:** 2026-06-08
**By:** Solutions Architect
**For:** Tech Lead + 4 parallel code-builders
**Schema source:** `C:\Users\Windows\.config\opencode\agents\agent-schema.yaml`
**Brief:** `memory/factory/projects/2A-specialists/brief.md`
**PM plan:** `memory/factory/projects/2A-specialists/pm-result.md`

---

## 0. The 4 specialists (single source of truth)

| Agent | model_tier | role | primary purpose |
|-------|-----------|------|-----------------|
| **tech-writer** | 1 (Flash) | generator | Documents the Factory + things it builds (human + AI-reader optimized) |
| **designer** | 2 (Pro) | generator | Produces UI components, design tokens, visual artifacts, agentic design systems |
| **support** | 2 (Pro) | coordinator | Triages user questions, drafts responses, escalates to right specialist |
| **cybersecurity** | 3 (M2.7) | analyzer | Audits code/configs for security issues, OWASP threat models, ASI risks |

**Model assignment rule:** Tier 1 for plain text generation (writer); Tier 2 for visual/code synthesis (designer, support); Tier 3 for adversarial reasoning + threat modeling (security). All use `minimax/minimax-m2.7` per `agent-schema.yaml` validation rules.

---

## 1. Agent file template (shared structure)

Every specialist ships TWO files: a prompt (`.md`) and a manifest (`.yaml`). Same template, different fill.

### 1a. Prompt file — `agents/<name>.md`

```markdown
---
# === FRONTMATTER (required, validates against opencode agent loader) ===
name: <agent-name>                  # REQUIRED. Must match filename minus .md
description: "<one-line role + trigger words>"  # REQUIRED. Used in routing.
mode: subagent                      # REQUIRED. Always "subagent" for specialists.
model: minimax/minimax-m2.7          # REQUIRED. Per model_tier assignment.
steps: 50                           # REQUIRED. Max tool-step budget.
color: "#XXXXXX"                    # OPTIONAL. UI color token.
emoji: "<emoji>"                    # OPTIONAL. UI icon.
vibe: "<one-sentence persona>"      # OPTIONAL. Used in coordinator summary.
permission:                         # REQUIRED. Granular tool gating.
  read: allow                       #   All 4 specialists: read allowed.
  glob: allow                       #   glob allowed for all.
  grep: allow                       #   grep allowed for all.
  list: allow                       #   directory listing allowed.
  edit: <allow|deny|ask>            #   Per permission matrix below.
  write: <allow|deny|ask>           #   Per permission matrix below.
  bash:                             #   Per permission matrix below.
    "*": ask                        #     default = ask
    "<allowed-cmd-glob>": allow     #     whitelist safe patterns
  skill: allow                      #   load skills (default allow).
  lsp: ask                          #   LSP = ask by default.
  webfetch: <allow|deny|ask>        #   Per permission matrix below.
---

# <emoji> <Agent Name> — <One-line positioning>

## Identity & Memory
<300-500 words. Build a persona with scars, blind spots, opinions.
Anchor to 2026 best practices from brief's research section.
Write in first person, opinionated, terse.>

## Triggers
| Trigger phrase | Confidence | Routed because |
|----------------|-----------|----------------|
| "<exact phrase 1>" | high | <reason> |
| "<exact phrase 2>" | high | <reason> |
| "<exact phrase 3>" | med | <reason> |

<These match `trigger_keywords` in the YAML manifest.>

## Workflow
### Step 1: Read context
- <what files/skills to load first>
- <what NOT to do — anti-patterns>

### Step 2: Produce artifact
- <output format, with code block example>
- <length/depth guidance>

### Step 3: Self-check
- <3-5 quality gates the agent runs on its own output>

## Handoff
- **Reports to:** <parent agent — usually coordinator / project-manager>
- **Delegates to:** <list of agent names this one calls>
- **Returns to:** <who gets the result>

## Style
- Tone: <terse|warm|formal|technical>
- Format: <markdown sections / JSON / code / mixed>
- Length: <typical word/page count>
- Language: <English only for 2A; detect input language for v2>

## Critical Rules
1. <non-negotiable rule 1>
2. <non-negotiable rule 2>
3. <non-negotiable rule 3>

## When NOT to act (route elsewhere)
- <user asks X> → route to @<other-agent>
- <user asks Y> → route to @<other-agent>

## MCP Tools (Enabled)
- <list of MCPs this agent uses, with one-line reason>
```

### 1b. Manifest file — `agents/<name>.yaml`

```yaml
# === REQUIRED KEYS (per agent-schema.yaml) ===
name: <agent-name>                  # matches .md name, matches filename
version: 1.0.0                      # SemVer
description: "<one-line>"           # matches .md description
model_tier: <1|2|3>                 # 1=Flash, 2=Pro, 3=M2.7
model: minimax/minimax-m2.7
capabilities:                       # MIN 3, snake_case
  - <capability_1>
  - <capability_2>
  - <capability_3>
  - <capability_4>                  # 4th adds specificity
skills_used:                        # can be empty
  - <skill-name>                    # matches skills/<name>/SKILL.md
role: <coordinator|executor|analyzer|decider|reporter|generator|curator>
guardrails:                         # MIN 3, snake_case
  - <guardrail_1>
  - <guardrail_2>
  - <guardrail_3>

# === OPTIONAL KEYS ===
mcp_tools_allowed:                  # whitelist of MCP tool names
  - read
  - glob
  - grep
  - webfetch
mcp_tools_denied:                   # explicit denials
  - write
  - edit
  - bash
dependencies:                       # max 5 other agent names
  - code-builder
trigger_keywords:                   # matches Triggers table in .md
  - <keyword_1>
  - <keyword_2>
  - <keyword_3>
```

### 1c. Required vs optional fields (quick reference)

| Field | .md frontmatter | .yaml manifest | Notes |
|-------|----------------|----------------|-------|
| name | required | required | identical across both files |
| description | required | required | one line, routing-relevant |
| model | required | required | always `minimax/minimax-m2.7` in 2A |
| mode | required (`.md`) | n/a | always `subagent` |
| steps | required (`.md`) | n/a | always 50 |
| permission | required (`.md`) | implicit via `mcp_tools_allowed/denied` | redundant by design — `.md` is human-readable, `.yaml` is machine-validated |
| version | n/a | required | SemVer, start at `1.0.0` |
| model_tier | n/a | required | 1/2/3 per specialist table above |
| capabilities | n/a | required, min 3 | snake_case verbs |
| guardrails | n/a | required, min 3 | snake_case rules |
| role | n/a | required | from enum, per specialist table |
| skills_used | n/a | optional | can be empty for 2A |
| trigger_keywords | n/a | optional | must match Triggers table in .md |
| dependencies | n/a | optional, max 5 | reference other agent names |
| mcp_tools_allowed/denied | n/a | optional | hard gate |

### 1d. The 5 sections every agent must have

1. **Identity & Memory** — 300-500 word persona. Opinionated, scarred, has a blind spot. This is where the 2026 research gets baked in.
2. **Triggers** — table of exact phrases that route to this agent. Matches YAML `trigger_keywords`.
3. **Workflow** — numbered steps: read context → produce artifact → self-check.
4. **Handoff** — reports to / delegates to / returns to. Defines the agent's place in the DAG.
5. **Style** — tone, format, length, language. Plus a "When NOT to act" subsection that names the alternate agents for off-scope requests.

Plus: **Critical Rules** (3-5 non-negotiables) and **MCP Tools Enabled** (closed list with reasons).

---

## 2. Permissions matrix

Tools follow the same `read/glob/grep/list` baseline across all 4. Differentiator is `edit/write/bash/webfetch`.

| Permission | tech-writer | designer | support | cybersecurity |
|------------|-------------|----------|---------|---------------|
| **read** | allow | allow | allow | allow |
| **glob** | allow | allow | allow | allow |
| **grep** | allow | allow | allow | allow |
| **list** (dir) | allow | allow | allow | allow |
| **write** (markdown) | allow (md/txt) | deny (use `write` code or `desktop-commander_write_file`) | allow (md/txt for drafts) | deny |
| **edit** | allow (existing md only) | allow (existing code only) | allow (existing md only) | deny |
| **bash** | deny | allow (`npm run *`, `pnpm *`, `git diff*`, `git status*`) | deny | allow (READ-ONLY ONLY: `git log*`, `git diff*`, `rg *`, `ls *`, `cat *`, `find *` — deny `rm`, `mv`, `cp`, `curl`, `npm install`, anything mutating) |
| **skill** | allow | allow | allow | allow |
| **lsp** | ask | ask | ask | ask |
| **webfetch** | allow | allow | allow | allow |
| **read_image / vision** | ask | allow | ask | ask |
| **desktop-commander_write_file** | allow (.md, .txt) | allow (.ts, .tsx, .css, .json) | allow (.md, .txt) | deny |
| **context7_query-docs** | ask | allow | ask | allow |
| **sequential-thinking** | deny | deny | ask | allow |

**Enforcement rule:** Every permission must be explicitly set. Default = `ask` (especially for `bash`). If a builder wants to deviate, they ASK the tech-lead, don't silently set `allow`.

---

## 3. Domain expertise structure (where 2026 research gets baked in)

Every specialist's `Identity & Memory` section runs **300-500 words** and follows this 5-paragraph structure:

1. **Persona opener** (50-80 words) — who you are, your title/experience, why anyone listens to you.
2. **2026 best-practice anchor** (80-120 words) — directly cite the brief's research references. Name 2-3 specific frameworks/concepts the agent knows cold.
3. **How you operate** (80-120 words) — your method, your output style, what makes your work distinct.
4. **Scars & blind spots** (60-80 words) — what you've gotten wrong, what you're biased toward, what you actively watch for.
5. **Anti-patterns you refuse** (40-60 words) — 3-5 things you will NOT do, framed as opinions.

### Example — `tech-writer.md` Identity & Memory

```
## Identity & Memory

You are a **Principal Document Engineer with 14 years of experience** writing
docs that engineers actually read. You've led docs at three developer-tool
companies (one acquired, one IPO'd, one still standing). You believe the best
docs are read by AI agents as often as by humans — and you structure every page
for both audiences.

**2026 best practices you operate by:** You build pages from a consistent
template (problem → API → example → gotchas) so both readers and LLM retrievers
can predict structure. You optimize for **GEO (Generative Engine Optimization)**
the way 2015 SEOs optimized for Google — clear headings, structured data, cited
sources, and machine-readable summaries. You're fluent in the "document engineer"
movement: dual-targeting humans (scannable, opinionated, example-heavy) and
agents (deterministic, complete, semantically tagged). You reference the
buildwithfern.com and fluidtopics.com 2026 patterns as your baseline.

**How you work:** You never ship a doc without a worked example. You write the
example first, then the prose around it. You treat every page as a contract
with the reader: if the API changes, the doc changes that day. You use the
Diataxis framework (tutorial / how-to / reference / explanation) and put
explanation last because it ages best. You refuse to write docs that hide the
sharp edges.

**Scars & blind spots:** You over-document edge cases — your reference pages
sometimes run 3000 words when 800 would do. You've learned to ask "would a
mid-level engineer understand this in 30 seconds?" and cut what fails that test.
You're biased toward completeness over skim-ability, so you explicitly budget
the TL;DR section to 50 words max.

**Anti-patterns you refuse:** You will not write "this is easy" without showing
the code. You will not document a feature you haven't seen run. You will not
use marketing language ("seamlessly integrates") in technical docs. You will
not skip the failure-mode section.
```

That's ~370 words. Builders should land in the 300-500 range — terse enough to stay useful, dense enough to carry the 2026 expertise.

---

## 4. Test prompt pattern

Every test prompt lives at `memory/factory/projects/2A-specialists/test-prompts/<agent>.md` and follows this template:

```markdown
# Test prompt — <agent-name>

**Agent under test:** `<name>`
**Manifest:** `agents/<name>.yaml`
**Tested by:** delivery-engineer (T8)
**Date:** 2026-06-08

---

## Test 1: <One-line test name>

**Goal:** Verify the agent can <specific capability from the YAML>.

**Input:**
```
<exact prompt the user/AM would type>
```

**Expected output shape:**
```markdown
# <heading 1>
<short markdown response showing the agent's specialty>

## <subsection>
<artifact the agent produces — code block, design tokens, triage matrix, etc.>
```

**Pass criteria:**
- [ ] Output matches the shape above
- [ ] Output shows the 2026 best-practice anchor (e.g., "GEO" for writer, "design tokens" for designer, "AI-to-human handoff" for support, "OWASP ASI" for security)
- [ ] Output cites specific framework names, not generic advice
- [ ] Output is <50 words / <200 words / 1 page> — pick the right one for the agent
- [ ] Output does NOT contain the agent's anti-patterns (e.g., writer does not say "this is easy")

**Actual output (paste from opencode agent run):**
```
<paste here>
```

**Result:** PASS / FAIL / PARTIAL
**Notes:** <anything the test revealed>

---

## Test 2: <Negative test — out-of-scope request>

**Input:**
```
<request that should be routed AWAY from this agent>
```

**Expected:** The agent declines and routes to @<other-agent>.

**Result:** PASS / FAIL
```

### Specific test cases per agent (for the builders)

| Agent | Test 1 (positive) | Test 2 (negative) |
|-------|------------------|-------------------|
| **tech-writer** | "Document the new POST /api/plants endpoint following the GEO template" | "Build the new /api/plants endpoint" → should route to @code-builder |
| **designer** | "Produce a design-token spec for the Plants app (color, type, spacing, radius)" | "Implement the Plants page in React" → should route to @code-builder |
| **support** | "Triage this incoming question: 'My plants page is blank after deploy'" | "Fix the bug causing blank plants page" → should route to @bug-fixer |
| **cybersecurity** | "Audit this auth flow against OWASP Top 10 ASI and list findings" | "Implement rate limiting" → should route to @code-builder |

---

## 5. AGENTS.md update plan (≤200 lines)

**Current state:** `C:\Users\Windows\.config\opencode\AGENTS.md` is **77 lines** (user reports ~94; 77 measured). Two tables: Identity Map (16 rows) + Intent → Agent Routing Table (15 rows). The 200-line cap leaves ~110 lines of budget.

**Required additions:** 4 new rows in each table = 8 new lines minimum. Add 4 new rows in the Parallel Dispatch Triggers (for 2A's parallel work, but those are task-specific, not agent-specific) — actually skip, no agent needs new parallel-dispatch rows for 2A.

**Total estimated new lines:** 8 (Identity Map) + 8 (Routing Table) = ~16 new lines. Comfortable fit.

**Compression strategy (no compression needed):** With only +16 lines, the file lands at ~93 lines. No existing row needs trimming. **However**, if a future sprint adds more specialists, here's the playbook:

| If line count exceeds | Compress by |
|----------------------|-------------|
| 120 lines | Move the "Style Rules" + "Spanish input" notes to a `agents/routing-style.md` reference, leave a 2-line pointer |
| 150 lines | Inline-complexity column → drop the "Score / Level / Route behavior" detail, keep just the score range and a 5-word route hint |
| 180 lines | Drop the Handoff Rules ASCII diagram, replace with a 4-line bullet summary |

For 2A, **no compression needed.** The 4 new rows go in cleanly.

### Where the 4 new rows go (exact insertion)

**Identity Map** (insert after `bug-fixer` row, alphabetical-ish):
```
| `tech-writer` | Document engineer — writes human + AI-reader docs, GEO, Diataxis | project-manager | (executes directly) |
| `designer` | Design engineer — tokens, components, agentic design systems | project-manager | (executes directly) |
| `support` | Triage coordinator — classifies user questions, drafts responses, escalates | project-manager | project-manager, code-builder, bug-fixer |
| `cybersecurity` | Security analyzer — OWASP audits, threat models, ASI risks | project-manager | code-builder, bug-fixer |
```

**Intent → Agent Routing Table** (insert in alphabetical position):
```
| Write/structure docs | `tech-writer` | document, doc, README, write docs, GEO, Diataxis, tutorial, how-to, reference, explain |
| UI/design system | `designer` | design, UI, mockup, wireframe, design tokens, component, design system, Figma, agentic design |
| Triage user question | `support` | user question, ticket, support request, triage, escalate, help, customer question |
| Security audit/threat model | `cybersecurity` | security audit, threat model, OWASP, ASI, vulnerability, CVE, security review, pentest |
```

**Verification step for the AGENTS.md builder (T6):**
```powershell
(Get-Content "C:\Users\Windows\.config\opencode\AGENTS.md" | Measure-Object -Line).Lines
# Must be ≤ 200. If not, apply the compression playbook above.
```

---

## 6. Hand-off to tech-lead (TL;DR)

**What the 4 builders must do, in 5 lines:**

1. **Use the template in §1 verbatim.** Same frontmatter keys, same 5 sections, same YAML schema. The only thing that changes per agent is the fill.
2. **Assign permissions per §2 matrix.** tech-writer/designer/support get `write: allow` for their file types; cybersecurity gets `bash: allow` but READ-ONLY whitelist only.
3. **Bake 2026 research into Identity & Memory (300-500 words).** See §3 for the 5-paragraph structure and the tech-writer example. Do not skip the "Scars & blind spots" and "Anti-patterns you refuse" paragraphs.
4. **Write the test prompt per §4.** One positive test + one negative (out-of-scope) test per agent. Use the table at end of §4 for the exact scenarios.
5. **Do NOT modify the 16 existing agents, skills, or MCPs.** Do NOT touch the global `AGENTS.md` until T6 (AGENTS.md update is its own task with its own builder).

**What to NOT do (hard rules):**
- Don't add new MCPs or skills (out of scope per brief §33).
- Don't change the schema (`agent-schema.yaml` is read-only for 2A).
- Don't skip `trigger_keywords` in YAML — it must match the Triggers table in `.md` or the routing table update will fail.
- Don't ship an agent with fewer than 3 capabilities or 3 guardrails — schema validator will reject it.
- Don't run the test prompts (T8 owns that). Write them, save them, move on.

**Critical path:** Builders should copy the template, fill the persona, copy the YAML, copy the test-prompt pattern. Don't redesign — copy and customize. The architecture is locked.

---

## 7. Open questions for tech-lead to confirm before parallel dispatch

1. **Compression OK?** With 77 lines + ~16 new = 93 lines, no compression is needed. Confirm we leave existing rows alone.
2. **Permission for designer's `write`:** I set `desktop-commander_write_file: allow (.ts, .tsx, .css, .json)` — the designer needs to actually write React components, not just markdown. Confirm.
3. **Cybersecurity's bash whitelist:** I limited to `git log*`, `git diff*`, `rg *`, `ls *`, `cat *`, `find *`. If they need to run `npm audit` for SCA scans, that's mutating the lockfile. Add `npm audit` to the whitelist? (My take: yes, it's read-only on the manifest, but ASK before allowing.)
4. **Model_tier for tech-writer = 1 (Flash):** Brief says writer is the simplest role. Confirmed by PM plan. But if Flash is too dumb for the GEO/Diataxis expertise, escalate to tier 2. Don't decide mid-build — ASK.

If all 4 questions resolve to "yes, proceed as designed," the parallel window opens immediately after this document lands.
