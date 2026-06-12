# Designer Agent — Build Result

## What was built

Built the **designer** specialist agent at `C:\Users\Windows\.config\opencode\agents\designer.md` (164 lines) following the locked template verbatim. Applied all template sections in order: frontmatter, Identity & Memory, Triggers, Workflow, Handoff, Style, Critical Rules, When NOT to act, MCP Tools.

## Frontmatter configuration

- `name: designer`
- `model: minimax/minimax-m2.7`
- `steps: 80`
- `mode: subagent`
- Permissions: read/glob/grep/list/skill/edit/write all allow; bash whitelisted to `npm run *`, `pnpm *`, `git diff*`; webfetch allow

## Identity & Memory (384 words)

Baked in 2026 research from brief: design tokens beyond colors/spacing (typography, radius, elevation, motion), Agentic Design Systems (autonomous agents assembling UIs from component inventories), modular multi-brand token architecture. Referenced designsystemscollective.com 2026 trends and supernova.io enterprise design systems. Persona: Senior Design Systems Architect, 18 years experience, scar tissue from "component graveyards." Anti-patterns: raw hex values, components without variant matrices, visual-only mockups, AI slop gradients.

## Deviation from template

None. Template applied verbatim. Steps set to 80 (vs tech-writer's 50) to accommodate the 7-step workflow (vs tech-writer's 6-step). Bash permissions added per architect authorization (tech-writer has bash denied). 14 triggers included (template calls for 8-12).

## Test prompts

Created `C:\Users\Windows\.config\opencode\memory\factory\projects\2A-specialists\test-prompts\designer.md` with 10 test prompts: 3 positive (design system with status types, component library expansion, brand token audit), 4 negative (copywriting, code implementation, accessibility audit, CSS bug fix), and 3 edge cases (unclear scope, multi-brand, visual-only mockup rejection).

## Verification

- File exists: `C:\Users\Windows\.config\opencode\agents\designer.md` (10,587 bytes, 164 lines)
- All 5 required sections confirmed present: Identity & Memory, Triggers, Workflow, Handoff, Style
- Template version locked at 2A-v1
- Schema reference to agent-schema.yaml included

## Skipped

Nothing. All 10 items in the brief were addressed. No routing table update (out of scope per brief §Scope: "4 agent files only" + "Routing table update in AGENTS.md" is separate scope from the 4 agent files themselves).