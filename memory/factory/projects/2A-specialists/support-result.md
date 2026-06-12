# Support Agent — Build Result

**Built by:** code-builder
**Date:** 2026-06-09
**Files created:** 2

---

## 1. Agent file: `C:\Users\Windows\.config\opencode\agents\support.md`

- **Lines:** 130
- **Frontmatter:** name, description, mode (subagent), model (minimax/minimax-m2.7), steps (60), permissions (read/glob/grep/list/skill allow, write allow md/txt only, webfetch allow, bash/lsp deny)
- **All 5 required sections present:** Identity & Memory, Triggers, Workflow, Handoff, Style
- **Additional sections:** Critical Rules, When NOT to act, MCP Tools (enabled)
- **Identity & Memory:** 300-500 words, first-person, opinionated, terse. Covers persona (11yr support specialist), 2026 anchor (kustomer.com/bluetweak.com auto-triage + knowledge-base-first), how you work (triage → respond → escalate), scars (bad handoff history), anti-patterns (5 refusals).
- **Triggers:** 12 entries (high/med confidence), covers all specified keywords.
- **Workflow:** 5 steps — read full message → categorize → draft response → escalate with full context → log interaction.
- **Handoff:** Reports to project-manager. Delegates to bug-fixer, tech-writer, project-manager, account-manager.
- **Style:** Empathetic, plain language, action-focused. 50-200 words per response.
- **Critical Rules:** 5 non-negotiable rules including never lose history, never use "we apologize", never escalate without best-guess answer.
- **When NOT to act:** Routes to bug-fixer (code), project-manager (features), code-builder (build), designer (UI), tech-writer (docs), cybersecurity (security), and internal agents.

---

## 2. Test prompts: `C:\Users\Windows\.config\opencode\memory\factory\projects\2A-specialists\test-prompts\support.md`

- **Positive (4):** deployment 500 error (bug report), password reset question, complaint about 3-day wait, escalation request to speak to human.
- **Negative (4):** JWT refactor (→ bug-fixer), SMS feature request (→ project-manager), internal agent roadmap question (→ account-manager/PM), SQL injection audit (→ cybersecurity).
- Each prompt includes expected behavior description.

---

## Verification

| Check | Result |
|-------|--------|
| File exists | ✅ `support.md` present at `agents/` |
| Line count | ✅ 130 lines |
| All 5 sections | ✅ Identity & Memory, Triggers, Workflow, Handoff, Style |
| Frontmatter complete | ✅ name, description, mode, model, steps, permissions |
| 2026 research baked in | ✅ kustomer.com, bluetweak.com, auto-triage, knowledge-base-first |
| Test prompts created | ✅ 4 positive + 4 negative prompts |
| Test prompts file path | ✅ `test-prompts/support.md` |

---

**Summary:** Built the support specialist agent matching the 2A template exactly. The agent has a strong identity (11yr senior support specialist with specific scars around bad handoffs), applies 2026 best practices (auto-triage, knowledge-base-first, no-lost-context handoff), and includes all 5 required sections plus Critical Rules and When NOT to act. 12 trigger phrases cover common support signals. 8 test prompts (4 positive / 4 negative) verify correct routing behavior. File passes all template checks.
