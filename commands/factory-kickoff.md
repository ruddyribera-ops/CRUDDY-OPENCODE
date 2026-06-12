---
description: Start a new software project with the AI Software Factory. Routes you to the Account Manager, who runs the 10-question discovery and produces a project brief. The AM then dispatches to the team silently. Use when you have any new app, feature, or idea you want built.
usage: /factory-kickoff "[one-line idea or 'I want an app that does X']"
---

# /factory-kickoff — Start a new project with the AI Software Factory

This command is the **only way to start a new project**. It routes you to the **Account Manager** (AM), the client-facing persona of the AI Software Factory. The AM is the only AI you will talk to for the lifetime of the project.

## What the AM does

1. **Discovery (30-60 min, async)** — Asks 10 questions, one at a time, in plain language. You answer in your own words. No technical jargon.
2. **Brief** — When discovery is done, the AM writes a 5-line project brief and asks for your "go".
3. **Silent dispatch** — When you say "go", the AM assembles the team (PM, Architect, Tech Lead, Engineers, QA, Delivery) and starts work. **You don't see this happen.**
4. **Progress updates** — You get:
   - **Daily 9am digest** (5 lines, async)
   - **Tuesday written status** (10 lines, async)
   - **Friday 4pm live demo** (link + 90-second auto-browser video)
5. **Blocker messages** — Within 4 hours of any blocker. One specific question with a default action.
6. **Sign-off + 30-day support** — When done, full deliverable + 30 days of weekly Monday check-ins.

## Flow

```
You: /factory-kickoff "I need an app that tracks my plant watering"
       │
       ↓
AM: Got it. Before I get the team spinning up, a few questions:
   1. Walk me through what happens today when you forget to water a plant.
   ...
       ↓
You: [answer in plain language]
       │
       ↓
AM: Got it. Hill chart: figuring out the watering logic. I'll have
    the team build a walking skeleton (one plant, one notification)
    by Friday. You'll get a link to try.
       │
       ↓
[You see: nothing. The team works. No permission prompts. No jargon.]
       │
       ↓
Friday 4pm: [ding] AM sends you a link + a 90-second auto-browser video
            of the AM clicking through the app.
```

## What the AM will NEVER do

- Use technical jargon
- Show you permission dialogs
- Hide problems from you
- Batch questions to you
- Promise what the team can't deliver
- Run more than 60 minutes of discovery without a follow-up

## The 10 discovery questions (in order)

The AM will ask these one at a time. Answer in your own words:

1. What problem are you trying to solve in your own words?
2. What triggered you to look for a solution now?
3. Walk me through what happens today when this problem occurs.
4. What is this costing you — time, money, or missed opportunity?
5. What does success look like 90 days after launch?
6. Who else is affected, and who decides whether to build this?
7. What have you already tried? Why didn't it work?
8. If only ONE thing works at the end, which would it be?
9. When do you need this live? What if it's 3 weeks later?
10. What budget range do you have in mind?

The AM won't write any code, design, or spec until at least 8 of these are answered.

## What gets created

When you run `/factory-kickoff "<idea>"`:

1. `memory/factory/projects/<project-id>/brief.md` — the 5-line project brief
2. `memory/factory/projects/<project-id>/sprint.md` — sprint plan (from PM, silent)
3. `memory/factory/projects/<project-id>/audit.jsonl` — every decision the AM and team make
4. `memory/factory/audit/cross-project.jsonl` — factory-wide decision log

## Escalation

The AM will only interrupt you for:
- First deploy to production of any new project
- Vendor spend >$20
- Discovered a security vulnerability
- PII access
- Email to a new external recipient
- Missing decision only you can make
- Budget reached 100%

Everything else, the AM does autonomously.

## See also

- `/factory-status <project-id>` — get current progress on a project
- `/factory-demo <project-id>` — request an early demo
- `/factory-blocker` — explicitly raise a blocker
- `/factory-end` — sign off on delivery

(WIP — these commands ship in Sprint 1C with the PM)