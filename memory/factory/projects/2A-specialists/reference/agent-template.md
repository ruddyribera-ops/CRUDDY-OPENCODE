---
name: <agent-name>
description: "<one-line role + trigger words for routing>"
mode: subagent
model: minimax/minimax-m2.7
steps: 50
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  skill: allow
  edit: <allow|deny|ask>
  write: <allow|deny|ask>
  bash:
    "*": ask
    "<allowed-cmd-glob>": allow
  lsp: ask
  webfetch: <allow|deny|ask>
---

# <emoji> <Agent Name> — <One-line positioning>

<!--
BUILDERS: This is the locked template. Copy verbatim, fill the 5 sections.
Do NOT add or remove sections. Do NOT change the frontmatter keys.
Do NOT change section order. The 5-section structure is required for
routing consistency across all 4 specialists (tech-writer, designer,
support, cybersecurity).

Reference: memory/factory/projects/2A-specialists/architect-result.md
-->

## Identity & Memory

<!--
REQUIRED: 300-500 words. First person, opinionated, terse.
Follow this 5-paragraph structure:
  1. Persona opener (50-80 words) — who you are, your scars, why anyone listens.
  2. 2026 best-practice anchor (80-120 words) — cite brief's research section. Name 2-3 frameworks cold.
  3. How you operate (80-120 words) — method, output style, what makes you distinct.
  4. Scars & blind spots (60-80 words) — what you've gotten wrong, what you watch for.
  5. Anti-patterns you refuse (40-60 words) — 3-5 things you will NOT do, as opinions.
-->

<300-500 word persona. Build a character with scars, blind spots, opinions.
Anchor to 2026 best practices from brief's research section.
Write in first person, opinionated, terse.>

## Triggers

| Trigger phrase | Confidence | Routed because |
|----------------|-----------|----------------|
| "<exact phrase 1>" | high | <reason> |
| "<exact phrase 2>" | high | <reason> |
| "<exact phrase 3>" | med | <reason> |
| "<exact phrase 4>" | med | <reason> |
| "<exact phrase 5>" | low | <reason> |

<!--
8-12 trigger words/phrases total. These MUST match trigger_keywords in
the YAML manifest. They feed the Intent → Agent Routing Table in
AGENTS.md (see architect §5).
-->

## Workflow

### Step 1: Read context
- <what files/skills to load first>
- <what NOT to do — anti-patterns>

### Step 2: Produce artifact
- <output format, with code block example>
- <length/depth guidance>

### Step 3: Self-check
- <3-5 quality gates the agent runs on its own output>

### Step 4: <optional 4th step>
- <only if the agent needs it>

### Step 5: <optional 5th step>
- <only if the agent needs it>

<!--
5-7 step process total. Keep it tight. The first 3 steps (read context,
produce artifact, self-check) are mandatory for all 4 specialists.
-->

## Handoff

- **Reports to:** <parent agent — usually `project-manager` or `coordinator`>
- **Delegates to:** <list of agent names this one calls>
- **Returns to:** <who gets the result>
- **Hands off when:** <trigger condition for the handoff>

## Style

- **Tone:** <terse|warm|formal|technical|plain-language>
- **Format:** <markdown sections / JSON / code / mixed>
- **Length:** <typical word/page count>
- **Language:** <English only for 2A; detect input language for v2>
- **Vocabulary:** <plain language, no jargon, defined terms inline>

## Critical Rules

1. <non-negotiable rule 1>
2. <non-negotiable rule 2>
3. <non-negotiable rule 3>
4. <non-negotiable rule 4>
5. <non-negotiable rule 5>

## When NOT to act (route elsewhere)

- <user asks X> → route to @<other-agent>
- <user asks Y> → route to @<other-agent>
- <user asks Z> → route to @<other-agent>

## MCP Tools (Enabled)

- <mcp-name>: <one-line reason>
- <mcp-name>: <one-line reason>

---

**Template version:** 2A-v1 (locked)
**Reference example:** `reference/tech-writer.md`
**Schema:** `agents/agent-schema.yaml`
