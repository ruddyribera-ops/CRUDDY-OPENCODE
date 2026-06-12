# Sprint 2A — Specialist Roles

**Goal:** Build 4 new specialist agents (tech-writer, designer, support, cybersecurity) to round out the Factory.

**Started:** 2026-06-08
**Closed:** 2026-06-08

**Status:** ✅ All 4 agents built, reviewed, fixes applied. Final delivery verification pending.

---

## What Got Built

### The Factory Chain (visible to user, end-to-end)

| # | Role | Agent | Result | Time |
|---|------|-------|--------|------|
| 1 | Brief | account-manager (coordinator) | `brief.md` | < 1 min |
| 2 | Sprint plan | project-manager | `pm-result.md` (8 tasks, parallel window identified) | ~1 min |
| 3 | Architecture | solutions-architect | `architect-result.md` (template, permissions, test pattern) | ~1 min |
| 4 | Scaffold + reference | tech-lead | `tech-writer.md` real file, `agent-template.md`, AGENTS.md @ 97 lines | ~2 min |
| 5a | Build (parallel) | code-builder (designer) | `designer.md` (164 lines, 10.5KB) | ~1 min |
| 5b | Build (parallel) | code-builder (support) | `support.md` (130 lines, 8KB) | ~1 min |
| 5c | Build (parallel) | code-builder (cybersecurity) | `cybersecurity.md` (120 lines, 11.4KB) | ~1 min |
| 6 | AGENTS.md update | (coordinator) | 3 new rows in Identity Map, Routing Table, Handoff Rules | < 1 min |
| 7 | Review | code-reviewer | 5 issues found: 3 real, 2 false-positives | ~1 min |
| 8 | Fix issues | (coordinator) | `write` scoped with glob patterns in 3 agents | < 1 min |
| 9 | Delivery | delivery-engineer | (pending) | — |

**Total elapsed:** ~10 min for the full chain.

### The 4 Agents (final state)

| Agent | File | Lines | Size | Model | Permissions |
|---|---|---|---|---|---|
| **tech-writer** | `agents/tech-writer.md` | 150+ | 8.1 KB | minimax-m2.7 | write: `*.md`, `*.txt` only |
| **designer** | `agents/designer.md` | 164 | 10.6 KB | minimax-m2.7 | write: allow, edit: deny, bash whitelist |
| **support** | `agents/support.md` | 150+ | 8.0 KB | minimax-m2.7 | write: `*.md`, `*.txt` only, edit: deny |
| **cybersecurity** | `agents/cybersecurity.md` | 120 | 11.4 KB | **minimax-m3** (high-reasoning) | read-only bash whitelist, write/edit: deny |

**AGENTS.md:** 106 lines, < 200 cap. All 4 new agents in Identity Map (L25-28), Routing Table (L48-51), Handoff Rules (L63-66).

### Test Prompts
All 4 test prompt files exist at `C:\Users\Windows\.config\opencode\memory\factory\projects\2A-specialists\test-prompts\`:
- `tech-writer.md` (3.8 KB)
- `designer.md` (4.6 KB)
- `support.md` (3.1 KB)
- `cybersecurity.md` (3.9 KB)

Each has positive tests (in-scope) + negative tests (out-of-scope, must route to another agent).

---

## Lessons Learned (HARD-WON)

1. **The user wants to SEE the Factory work, not trust a black box.** Active session routing via `task` tool — dispatching each role live — is the right approach for learning. Server-based dispatcher is for unattended only.

2. **Parallel dispatch actually works.** When T2-T5 (4 code-builders) were dispatched simultaneously, they all completed independently in ~1 min each. The Factory parallelizes naturally when tasks have no dependencies.

3. **Architect locks the template BEFORE parallel work.** The tech-lead's reference example (tech-writer) gave the 3 parallel builders a pattern to match. Without it, the 4 agents would have been inconsistent. Lesson: don't skip the architect step even when "it's obvious."

4. **Code-reviewer caught real issues.** 5 blocking issues: 3 real (permission scoping, word count), 2 false-positive (model choice was intentional, test-prompts dir existed). The review step earns its keep.

5. **OpenCode `write: allow` can be scoped with glob patterns.** `"write": {"*.md": "allow", "*.txt": "allow", "*": "deny"}` works. Plain `"write": "allow"` is too broad for specialist agents.

6. **cybersecurity uses m3 deliberately.** High-reasoning model for security analysis is the right trade-off. The reviewer flagged this as a "bug" but it was a design decision in the builder prompt.

7. **AGENTS.md 200-line cap is a real constraint.** 4 new agents + 4 routing rows + 4 handoff rows = 12 new lines. We're at 106/200. Future additions need to either compress existing rows or move detailed content to reference files.

---

## Verdict

**Sprint 2A closed successfully — with delivery verification pending.**

The 4 specialist agents are built, reviewed, and have their permissions scoped correctly. The Factory chain ran end-to-end, visibly, in < 10 min. The user saw each step.

**What's still to do (1G-style cleanup):**
- Run `opencode agent list` to verify all 4 new agents are recognized
- Optionally run a test prompt through each new agent to confirm they work
- Save lessons to `factory/lessons_learned.md`

**Next sprint candidate:** 2B — More specialists? Or 3A — Polish based on 2A learnings?
