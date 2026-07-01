---
name: common
description: Cross-cutting rules that apply to ALL agents. The single source of truth for tool-call budgets, banned phrases, frontmatter template, handoff format, and forbidden action enforcement.
triggers: applies to all agents by default
applies_to: all 21 agents in agents/
---

# Common Agent Rules (Cross-Cutting)

> The single source of truth for rules that affect every agent. Update here, not in individual agent files.

## 1. Tool-Call Budget

**Every agent has a hard cap of 15 tool calls without writing or editing a file.**

If you have made more than 15 tool calls without writing or editing any file:
1. **STOP.** You are investigating, not executing.
2. **Re-evaluate.** Have you read enough? Are you exploring without purpose?
3. **Either commit to an edit or report status to the user.** Continued tool calls without output is wasted context.

**Why this exists:** token waste, runaway exploration, sub-agent infinite loops. Born from repeated observations across code-builder, bug-fixer, and other specialists.

## 2. Banned Phrases (Anti-Patterns)

Never say or think any of these. Each has a replacement:

| Banned | Instead |
|--------|---------|
| "I'll just take a quick look at the code" | Dispatch to code-analyzer |
| "This is simple enough for me to do directly" | Dispatch to the right specialist |
| "Let me fix this small thing while I wait" | Dispatch to bug-fixer |
| "I should just run this bash command" | Dispatch to delivery-engineer |
| "Let me check what's happening" | Dispatch to code-analyzer |
| "I'll handle this for you" | Dispatch to the relevant specialist |
| "Let me do the technical work" | Dispatch to the relevant specialist |
| "I'll just check the logs" | Dispatch to code-analyzer |
| "This is small, I'll write it myself" | Dispatch to code-builder |
| "I can debug this quickly" | Dispatch to bug-fixer |
| "Let me run a quick test" | Dispatch to qa-engineer |
| "I'll just verify the deployment" | Dispatch to delivery-engineer |
| "Let me check the documentation" | Dispatch to tech-writer |
| "I'll read this file myself" | Dispatch to code-analyzer for deep reads |
| "Let me fix this real quick" | Dispatch to bug-fixer |
| "I'll handle the deployment" | Dispatch to delivery-engineer |
| "The sub-agent failed, let me just do it myself" | Re-dispatch ONCE with simplified prompt |
| "Let me take care of it" | Dispatch |
| "I'll just verify" | Dispatch verification, don't self-verify |

**Why this exists:** the AM broke this rule in 2026-06-18 PRIA v10 demo prep (4-hour session, should have been 45 min). Documented in `account-manager-discipline.md`.

## 3. YAML Frontmatter Template (Canonical)

Every agent `.md` file MUST have this frontmatter:

```yaml
---
name: <agent-id-lowercase-hyphenated>
description: <one-line role summary>
when: "Use for: <trigger conditions>. NEVER for: <out-of-scope conditions>."
do_not: "<forbidden actions list>"
triggers:
  - <trigger 1>
  - <trigger 2>
  - <trigger 3>
forbidden_triggers:
  - <out-of-scope trigger 1>
  - <out-of-scope trigger 2>
---
```

**Field rules:**
- `name`: lowercase, hyphenated, matches filename without .md
- `description`: max 1 sentence, no jargon
- `when`: "Use for" + comma-separated triggers, "NEVER for" + out-of-scope
- `do_not`: forbidden actions (in agent's own words)
- `triggers`: list of phrases that activate this agent
- `forbidden_triggers`: list of phrases that should NOT activate this agent (use the alternative)

**Why this exists:** inconsistent frontmatter makes agent discovery unreliable. Some agents have rich frontmatter, others have none. This is the standard.

## 4. Handoff Format (Canonical)

Every agent's handoff section MUST include both directions:

```markdown
## Handoff

**I dispatch TO:**
- `<agent-id>` when `<condition>`
- `<agent-id>` when `<condition>`

**Routes TO me when:**
- `<condition>` → AM dispatches me
- `<condition>` → main-coordinator routes me
```

**Why this exists:** current agent files document who they dispatch TO but rarely who dispatches TO them. Makes backward-traceability through the system impossible without reading every agent.

## 5. Forbidden Action Enforcement

Lists of "Never Do" or "Forbidden Actions" are non-binding without enforcement. To make them binding:

1. **State the constraint explicitly** (don't just list it)
2. **State the consequence of violation** (what breaks, what the user sees)
3. **State the alternative** (what to do instead, with specialist name)
4. **Add a self-check prompt** at the end of any high-risk task:

```
Self-check before declaring done:
- [ ] Did I write code? (forbidden for AM)
- [ ] Did I run bash? (forbidden for AM)
- [ ] Did I make an architecture decision? (forbidden for AM)
If any of these: I broke the rule. Stop. Dispatch.
```

**Why this exists:** "Never" lists without enforcement get ignored. Adding a self-check creates a forcing function.

## 6. Updating These Rules

These are cross-cutting. To change them:
1. Update this file (`common.md`)
2. Have all agents reference the new version (no per-agent update needed)
3. If a rule becomes agent-specific, MOVE it to that agent's file, not duplicate

**Anti-pattern:** having the same rule in 5 agent files. Drift guaranteed.
