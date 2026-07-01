---
name: awesome-ask-questions-if-underspecified
description: "Pause-and-clarify pattern — from Trail of Bits. Use when user request is ambiguous, underspecified, or has multiple plausible interpretations. Triggers: clarify, ambiguous, underspecified, ask user, what do you mean, missing context, scope unclear, constraints missing."
triggers:
  - "awesome-ask-questions-if-underspecified"
  - "ask questions if underspecified"
  - "when to use ask questions if underspecified"
  - "how to ask questions if underspecified"
  - "ask questions if underspecified examples"
  - "ask questions if underspecified pattern"
applies_to:
  - "main-coordinator"
---


# Ask Questions If Underspecified Skill

*Based on the Trail of Bits methodology.*

## When to Use

Activate this skill when a user request has:

1. **Ambiguous objectives** — "make it better" could mean performance, UX, or security
2. **Unclear scope** — no file paths, no language, no framework specified
3. **Missing constraints** — no budget, timeline, or technical boundaries

## When to Ask (3 Conditions)

| Condition | Example | Response |
|-----------|---------|----------|
| Multiple valid interpretations | "help me with auth" | Ask: "What kind — login, API keys, OAuth?" |
| Scope undefined | "build something" | Ask: "What domain? What problem does it solve?" |
| Constraints missing | "make it fast" | Ask: "Current baseline? Target latency?" |

## When NOT to Ask

**Pick reasonable defaults and document them.** Don't ask for:
- Trivial choices with no wrong answer (tab vs spaces)
- Obvious preferences (variable naming)
- Information you can infer from context

```markdown
# Instead of asking:
"Should I use PostgreSQL or SQLite?"

# Just pick and document:
"Using SQLite (simpler for single-instance, can migrate later).
To change: set DATABASE_URL=postgresql://..."
```

## What to Ask

### Specific Question Patterns

**Ambiguous scope:**
- "What files does this affect?"
- "Which service/module is this for?"
- "What's the target environment — local, staging, prod?"

**Undefined requirements:**
- "What should the output look like?"
- "What's the acceptance criteria?"
- "What does 'done' mean for this task?"

**Missing context:**
- "Is this part of a larger feature?"
- "Are there existing patterns I should follow?"
- "What's the priority — speed or quality?"

### Using AskUserQuestion

```markdown
Via AskUserQuestion, ask:

> I need to clarify the scope before proceeding.
>
> What's the target for this change?
> - A) Single file (specific file I name)
> - B) Multi-file (an entire module)
> - C) Whole project (major refactor)
```

**Rule:** Ask ONE question at a time. Wait for response before continuing.

## The Cost of Guessing vs Asking

| Guessing | Asking |
|----------|--------|
| Wrong direction = wasted work | 30 seconds now = hours saved |
| May need to redo entirely | Clear path forward |
| User frustrated | User feels heard |

**The math:** A 2-minute clarification question prevents 2 hours of wrong implementation.

## Anti-Sycopnancy Rules

**Never say during clarification:**
- "That's interesting..." — take a position
- "There are many ways..." — pick one and explain why
- "You might want to consider..." — say what's correct

**Always say:**
- "I need to clarify X before proceeding"
- "The ambiguity is between A and B — which is right?"
- "I'll assume Y unless you say otherwise"

## Quick Reference

```
When activated by:
- "fix it" (no context)
- "improve X" (vague)
- "help me with that" (unclear reference)
- "build something" (no scope)
- "make it better" (undefined metric)

Ask ONE clarifying question.
Wait for answer.
Document assumption.
Proceed.
```

## Attribution

This methodology is adapted from Trail of Bits — known for rigorous security thinking applied to software development process. The "pause and clarify" pattern prevents costly misalignments before work begins.

## Anti-Patterns

- ❌ Asking multiple questions at once
- ❌ Asking questions you can infer from context
- ❌ Proceeding without documenting assumptions
- ❌ Saying "I assumed X" without telling the user
- ❌ Asking for trivial preferences