<!-- This file is referenced from agents/main-coordinator.md -->
<!-- All content in this file is STATIC REFERENCE — tables, enumerations, mappings -->
<!-- Behavioral logic (routing, dispatch, hard rules) stays inline in main-coordinator.md -->

---

## Complexity Auto-Detection Indicators (Referenced from main-coordinator.md)

| Level | Score | Indicators | Behavior |
|-------|-------|------------|----------|
| **Trivial** | 0 | "typo", "rename", "read me", single file, ≤3 lines | Route fast, minimal checks |
| **Simple** | 1-3 | "add one function", "fix a variable", single-file change, ≤10 lines | Standard route, single skill |
| **Moderate** | 4-6 | "refactor module", "add feature", "fix bug", 2-5 files | Generate task_graph IF multi-domain. POA + parallel dispatch + Fan-In verify. |
| **Complex** | 7-10 | "architecture", "full-stack", "new project", "migration", "security", 5+ files, multiple domains | DAG MANDATORY: task_graph → parallel batches → Fan-In verify → aggregate |

**Auto-detection keywords:**
- **Trivial:** read, show, typo, what is, where is, rename
- **Simple:** add, fix (simple), update, change (one thing), remove
- **Moderate:** refactor, debug, feature, fix (multi-step), implement, multiple files
- **Complex:** design, architecture, from scratch, full-stack, migration, rewrite, secure, scale, new project

---

## Thinking Model Routing (Referenced from main-coordinator.md)

**Constraint:** No deepseek-v4-pro. Use MiniMax M2.7 as workhorse, M3 only for brief bursts (token intensive).

| Complexity | Model | MCP | When to use M3 |
|------------|-------|-----|----------------|
| 0-6 | minimax-m2.7 (default) | sequential-thinking if ≥4 | Never — M2.7 is sufficient |
| 7-8 | minimax-m2.7 | sequential-thinking **forced ON** | Only if ≤5min task → brief M3 burst |
| 9-10 | minimax-m2.7 | sequential-thinking **forced ON** | M3 burst for architecture only, then revert |

**Rules:**
- M3 is a **burst tool only** — never persistent high-reasoning mode
- For complexity 7+: route with `sequential-thinking` MCP explicitly requested in the handover
- For complexity 9-10 that are architecture/planning tasks: brief M3 window, then switch back
- Default model: minimax-m2.7 — no model name in output, no announcement

---

## Research-First Gates (Referenced from main-coordinator.md)

**BEFORE routing, always check if task needs research first:**

| Condition | Action |
|-----------|--------|
| User mentions unfamiliar library or tool | Research before routing: use context7 or fetch for docs |
| Error message mentions obscure package | Check library docs via context7 before routing to bug-fixer |
| Architecture request with multiple tech options | WebSearch comparison articles first |
| Security best-practice question | Read security-basics skill first |
| Deployment/platform choice | Research current Railway pricing/caps if deploy-related |
| Any "what's the best X for Y" | WebSearch current comparisons (not memory) |

### Opensource Auto-Fetch (Referenced from main-coordinator.md)

When the task mentions a well-known open-source library (streamlit, fastapi, react, express, sqlalchemy, pytest, etc.) and the project doesn't already have `_source/<org>/<repo>/`, run `python scripts/opensource.py clone <url>` in the background.

**Known library mapping (auto-detect):**
| Library | GitHub URL |
|---------|-----------|
| streamlit | https://github.com/streamlit/streamlit |
| fastapi | https://github.com/fastapi/fastapi |
| react | https://github.com/facebook/react |
| express | https://github.com/expressjs/express |
| sqlalchemy | https://github.com/sqlalchemy/sqlalchemy |
| pytest | https://github.com/pytest-dev/pytest |
| httpx | https://github.com/encode/httpx |
| pydantic | https://github.com/pydantic/pydantic |
| jinja2 | https://github.com/pallets/jinja |
| click | https://github.com/pallets/click |
| next.js | https://github.com/vercel/next.js |
| vue | https://github.com/vuejs/core |
| vite | https://github.com/vitejs/vite |

### Browser Automation — Tool Decision (Referenced from main-coordinator.md)

| Condition | Use | Why |
|-----------|-----|-----|
| Localhost/dev/staging site, standard UI testing | Playwright MCP | Zero setup, native MCP tools |
| Site has Cloudflare/Turnstile/bot detection | browser-robust (`scripts/browser.py`) | CloakBrowser stealth pass |
| Unknown site scraping, adaptive selectors needed | browser-robust | Scrapling handles redesigns |
| Playwright MCP gets blocked/times out | Fallback → browser-robust | Belt-and-suspenders |

**Full decision doc:** `rules/browser_tool_decision.md`

---

## Discovery Gate Question Templates (Referenced from main-coordinator.md)

| Scenario | Example questions |
|----------|------------------|
| Build something new | "What problem does this solve? What should the output look like? Who uses it?" |
| Fix something broken | "What's happening vs what should happen? Any error messages?" |
| Add a feature | "What should it do? Where should it fit in the existing flow?" |
| Analyze something | "What specifically do you want to know about it?" |

---

## Parallel Dispatch Auto-Detection Triggers (Referenced from main-coordinator.md)

| If task involves... | Then... |
|---------------------|---------|
| Frontend + Backend code | Launch `@code-builder`(frontend) + `@code-builder`(backend) in parallel |
| Feature + Architecture decision | Launch `@architecture-advisor` + `@code-builder` in parallel |
| Bug + Impact analysis | Launch `@bug-fixer`(root cause) + `@code-analyzer`(impact) in parallel |
| Code build + Test writing | Launch `@code-builder` + `@code-builder`(tests) in parallel |
| Refactor + Design validation | Launch `@code-builder` + `@architecture-advisor` in parallel |
| Multi-file feature (≥3 files, ≥2 domains) | Launch ALL relevant specialists in parallel |
| Feature + adversarial test | Launch `@code-builder` + `@expert-tester` in parallel |
| AI/LLM feature build | Launch `@code-builder` + `@ai-evaluator` in parallel |
| Production incident + post-deploy monitoring | Launch `@delivery-engineer` + `@observability-sre` in parallel |

### When NOT to Parallel-Launch

- **Trivial/Simple tasks** (score 0-3): single specialist is faster
- **Same-file edits**: two agents modifying the same file = merge conflict
- **Sequential dependency**: Agent B literally needs Agent A's output to start
- **User explicitly asked for one thing**: don't over-engineer

---

## Swarm Mode — When to Use Swarm vs DAG (Referenced from main-coordinator.md)

| Condition | Use |
|-----------|-----|
| Single-domain task (frontend only, bug fix, etc.) | DAG routing (default) |
| Multi-domain, sequential pipeline (PM → backend → frontend → QA → deploy) | Swarm |
| User explicitly says "use swarm", "full team", or "all agents" | Swarm |
| Task has retry logic, approval gates, or state machine needs | LangGraph workflow |
| Quick parallel tasks (3+ independent) | DAG parallel batches |

---

## Evaluator-Optimizer Loop Trigger Conditions (Referenced from main-coordinator.md)

| Condition | Behavior |
|-----------|----------|
| Task complexity ≥ 4 (Moderate/Complex) AND ≥ 3 files | Always trigger loop |
| User explicitly says "review my code" | Route directly to `@code-reviewer` |
| Tier 3 pipeline task | Always trigger loop |
| Trivial/Simple (<3 files) | Skip loop — single agent faster |

---

## Architect Pack Files (Referenced from main-coordinator.md)

| File | Created by | Read by |
|------|-----------|---------|
| `workflows/architect-pack-template.md` | (template) | architecture-advisor |
| `planning/sprints/sprint-NNN/requirements.md` | architecture-advisor | builder |
| `planning/sprints/sprint-NNN/blueprint.md` | architecture-advisor | builder |
| `planning/sprints/sprint-NNN/acceptance.md` | architecture-advisor | builder |
| `planning/sprints/sprint-NNN/risks.md` | architecture-advisor | builder |

---

## DAG Patterns Reference (Referenced from main-coordinator.md)

| Pattern | When | Execution |
|---------|------|-----------|
| **Fan-out** | 3+ independent sub-tasks | All in parallel (batch 1) |
| **Pipeline** | A → B → C (linear dependency) | Sequential, one at a time |
| **Fan-in** | A + B → C (multiple sources, one consumer) | A ‖ B → C after both done |
| **Branch** | If condition → path X, else → path Y | Decision gate, then one path |

---

## Checkpoint Protocol Reference (Referenced from main-coordinator.md)

| Trigger | Action |
|---------|--------|
| Task starts (Moderate+, POA present) | Write `memory/checkpoint.yaml` with all items `pending` |
| Agent reports POA item done | Update checkpoint: mark item `done` + file + line count |
| Task completes (all POA done) | Delete checkpoint file |
| Task fails mid-execution | Keep checkpoint, offer resume prompt |

---

## Slash Commands Reference (Referenced from main-coordinator.md)

| Command | What it does | Route to |
|---------|-------------|----------|
| `/rules` or `check rules` | Scan code against agent rules | Run `scripts/check-rules.py check .` directly |
| `/review` or `review code` | Auto review-loop on changed files | Run `scripts/review-loop.py run .` directly |
| `/clean` or `clean source` | Remove cloned source code | Run `scripts/opensource.py clean` directly |

---

## Challenger Rule Trigger Keywords (Referenced from main-coordinator.md)

| Category | Keywords/phrases to match | Mandatory challenge |
|---|---|---|
| Weak crypto | `md5`, `sha1`, `sha-1`, `plain text password`, `encrypt password`, `custom hash`, `obfuscate password` | "That's broken for passwords — bcrypt or argon2. Use one of those?" |
| Auth shortcuts | `skip auth`, `disable auth`, `bypass login`, `no auth for now`, `trust the client`, `skip jwt` | "Skipping auth ships a security hole. Minimal auth (bcrypt + session cookie) is 20 lines. Do that instead?" |
| Silent failure | `except: pass`, `except Exception: pass`, `catch (e) {}`, `catch {}`, `swallow error`, `ignore error` | "Silencing errors hides the bug that will bite next. Log it at minimum. Proceed with logging + re-raise?" |
| Type escape | `ts-ignore`, `@ts-ignore`, `: any`, `as any`, `noqa`, `# type: ignore` | "That mutes the type checker that's trying to tell you something. Want to fix the underlying type instead?" |
| Destructive git | `--force`, `-f ` (in git context), `--no-verify`, `reset --hard`, `push --force`, `force push`, `skip hooks` | "That's destructive/skips safety. Confirm you mean it, or want the safer form?" |
| Overkill stack | `add redis`, `add kafka`, `add microservice`, `kubernetes`, `rewrite in`, `migrate to (new framework)` | "That's heavy for the current scale. Start simpler (name the lighter option). Upgrade only when you hit a real wall?" |
| Deploy-and-pray | `deploy without test`, `skip tests`, `just push it`, `test in prod`, `we'll fix it in prod` | "On Railway, stale-build caching has burned you before. Want the commit-hash-verify step from `deployment-patterns` first?" |
| Fresh-DB amnesia | `new deploy`, `first deploy`, `fresh database`, `empty db`, `reset db` (without "seed" mentioned) | "Fresh DB means no users = broken login. Confirm seed-on-startup is wired (see `database-patterns` + `deployment-patterns` first-deploy checklist)?" |
| Timer-based fixes | `sleep(`, `setTimeout` (for "waiting for something to be ready"), `wait_for_timeout`, `time.sleep` in a test | "Timers flake under load (see `feedback_e2e_waits.md`). Want `wait_for_selector` / polling / explicit signal instead?" |
| Fresh-package risk | `pip install`, `npm install`, `add` (any package name) — when the package is unknown to the project | "That package was released recently / is unfamiliar. Check if it's older than 14 days before installing. New packages are the #1 supply-chain attack vector. Proceed with audit anyway?" |

---

## Direct-Work Escape Hatch Allowed Patterns (Referenced from main-coordinator.md)

| Pattern | Example | Allowed? |
|---|---|---|
| Typo fix in a comment or docstring | "fix the typo in the README" | ✅ |
| Answering a factual question about a file | "what language is this?" | ✅ |
| Reading a file back | "show me line 42 of foo.py" | ✅ |
| Renaming ONE unused variable in ONE place | "rename `temp` to `scratch` in util.py:42" | ✅ |
| Removing ONE unused import | "drop the unused `os` import" | ✅ |
| Anything else | — | ❌ ROUTE |

---

## Gate System Proof Types (Referenced from main-coordinator.md)

| Type | Checks |
|------|--------|
| `file-exists` | File exists + SHA256 recorded |
| `grep-null` | Grep returns nothing (clean state) |
| `test-output` | Test file + SHA recorded to artifacts/ |
| `curl-200` | HTTP 200 confirmed |
| `manual` | Coordinator manual approval |
| `summary-sha` | Summary logged + SHA |
