<!-- This file is referenced from agents/code-builder.md -->
<!-- All content in this file is STATIC REFERENCE — tables, enumerations, checklists -->
<!-- Behavioral logic (implementation steps, hard rules) stays inline in code-builder.md -->

---

## Pipeline Fidelity Tiers (Referenced from code-builder.md)

Before starting ANY task, auto-select the right pipeline tier:

| Tier | Name | When | Steps | Auto-Detect Keywords |
|------|------|------|-------|---------------------|
| **1** | **Fast** | Single-pass, ≤3 lines, typo-level fixes | Skip skill read ↑ skip POA ↑ edit ↑ skip verify (trivial) | typo, rename, comment, one-line |
| **2** | **Standard** | Most tasks — write + self-review | Skill read ↑ POA (if ≥2 files) ↑ implement ↑ self-review ↑ verify ↑ report | Default (no tier keywords) |
| **3** | **Thorough** | Complex features, multi-file, multi-domain | Skill read ↑ Context7 (if needed) ↑ POA ↑ implement ↑ self-review ↑ test ↑ verify ↑ completion audit ↑ report | complex, full-stack, multi-file, refactor, migration, production |

**Selection rules:**
- If task fits **Tier 1 criteria exactly** ↑ use Tier 1. No exceptions for anything touching auth, DB, security, or test files.
- If task mentions "complex", "production", "migration", or involves 5+ files ↑ **Tier 3**.
- Default: **Tier 2** (most tasks).

---

## Self-Review Checklist (Referenced from code-builder.md)

After implementing, BEFORE declaring done, run this self-review:

```
## Self-Review Checklist
- [ ] Code follows project patterns (same style, same structure)
- [ ] No `any` or `ts-ignore` introduced
- [ ] No empty files or TODO-as-implementation
- [ ] No unused imports/variables
- [ ] Error paths handled (not just happy path)
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Public API surface is intuitive (hard to misuse)
- [ ] All existing tests still pass (no regressions)
- [ ] If new feature: are there tests?
```

Only after all items are checked ↑ proceed to verification.

---

## Skill Selection Reference (Referenced from code-builder.md)

Before writing ANY non-trivial code, read the matching skill from `~/.config/opencode/skills/<name>/SKILL.md`:

| If task involves... | Read this skill |
|---------------------|-----------------|
| **ALL tasks (required)** | `skills/karpathy-guidelines/SKILL.md` — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution |
| API endpoints, routes, middleware | `skills/api-patterns/SKILL.md` |
| Login, password hashing, JWT, sessions | (no matching skill — skip) |
| Database, SQL, migrations, queries | `skills/database-patterns/SKILL.md` |
| Writing or fixing tests | `skills/testing-and-debugging/SKILL.md` |
| TypeScript, React, modern JS | (no matching skill — skip) |
| Python, FastAPI, Pydantic | (no matching skill — skip) |
| Data analysis, CSV, JSON parsing | (no matching skill — skip) |
| Docker, Railway, deployment | `skills/deployment-patterns/SKILL.md` |
| WebSocket, SSE, real-time | (no matching skill — skip) |
| Git operations, commits | (no matching skill — skip) |
| CI/CD pipelines, GitHub Actions | `skills/deployment-patterns/SKILL.md` |
| Code quality, refactoring | `skills/differential-review/SKILL.md` |
| UI, CSS, layout, design, styling | `skills/ui-design/SKILL.md` |
| Input validation, XSS/SQLi/CSRF, secrets, OWASP | `skills/security-basics/SKILL.md` |
| Bundle size, lazy loading, memoization, query perf, caching | `skills/performance-optimization/SKILL.md` |
| Word/.docx, Excel/.xlsx, PowerPoint/.pptx generation or parsing | (no matching skill — skip) |
| OCR, text-from-image, Tesseract, EasyOCR | `skills/ocr-tools/SKILL.md` |

**Read 1–2 skills max per task. Pick the closest match.**

---

## Parallel-Opportunity Check (Referenced from code-builder.md)

Before starting solo work, check if this task could benefit from a parallel agent:

| If your task involves... | Request coordinator to add... |
|---|---|
| Frontend AND backend code | `@code-builder` for the other layer |
| Implementation AND testing | `@code-builder` for tests |
| New feature AND architecture tradeoff | `@architecture-advisor` for design validation |
| Code AND documentation | `@code-explainer` for docs |

**How:** Flag in your first response: `🔁 Parallel opportunity: [other agent] for [domain]`. The coordinator will launch it. Don't silently work alone when parallel is faster.

**Skip if:** task is single-file, single-domain, or < 10 lines.

---

## Anti-AI Quality Gates — Slop Check (Referenced from code-builder.md)

Before declaring done, run these gates on EVERY file you created or modified. If ANY gate fails, FIX the file — don't skip.

| # | Gate | What to check | Fix it |
|---|------|---------------|--------|
| 1 | **No placeholders** | No `TODO`, `FIXME`, `REPLACE_ME`, `CHANGE_THIS`, `// TODO`, `# TODO` as file body | Replace with real content or remove the line |
| 2 | **No dead code** | No unused imports, no variables declared but never read, no commented-out code blocks | Remove them |
| 3 | **No generic names** | No `temp`, `data`, `stuff`, `thing`, `helper`, `utils` as module/function/class names (except actual utility modules) | Rename to describe what it is |
| 4 | **No empty handlers** | No `except: pass`, `except Exception: pass`, `catch (e) {}`, empty callback bodies | At minimum log. If expected, add comment explaining why |
| 5 | **No magic numbers** | No bare numbers in code without explanation. `42` is magic. `TIMEOUT_SECONDS = 42` is not. | Extract to named constant |
| 6 | **No debug artifacts** | No `console.log`, `print()`, `console.debug` left in final code (except CLI apps where print is intentional) | Remove or gate behind a `--verbose` flag |
| 7 | **No overly long functions** | Any function > 50 lines? | Split into smaller functions |
| 8 | **Error messages are actionable** | No "Something went wrong" or "Error occurred" — tells the user nothing | Include what failed and what to do: "Failed to connect to DB at host:5432 — check credentials" |
| 9 | **No AI boilerplate** | No generic "As an AI language model..." comments, no overly verbose docstrings that restate the code | Remove. Let code speak. Keep only why-not-obvious docs |
| 10 | **Consistent style** | Code matches project style (check `.opencode/constitution.md` if present) | Run formatter. Fix naming mismatches. |

**Hard rule:** If any gate flags a file, fix it before moving to STEP 5. Do NOT report "done" with gate failures.

---

## Tool Authority Tiers (Referenced from code-builder.md)

When choosing tools, classify the action into one of four tiers and adjust your behavior:

| Tier | Tools | Your behavior |
|------|-------|---------------|
| **Read-only (free)** | `read`, `glob`, `grep`, `list`, `lsp`, `skill` | Use freely. No announcement needed. |
| **Propose-edit (gated)** | `edit` (search_replace) | State the diff in 1 line before applying. Wait for confirmation if scope > 1 file. |
| **Execute (most-gated)** | `bash`, `webfetch`, `external_directory` | Quote the exact command before running. Never chain destructive ops without an explicit `confirm:` step. |
| **Destructive (always-gated)** | `bash` commands containing `rm`, `del`, `drop`, `truncate`, `>`, `move`, `git push --force`, `git reset --hard` | STOP. Surface the command, the blast radius (what files/rows/branches it affects), and ask before running. Never batch destructive ops with non-destructive ones. |

**Hard rule:** If a tool call has the blast radius of `rm -rf` or equivalent, it's not Tier 3 — promote it to Tier 4. Confirm explicitly.
