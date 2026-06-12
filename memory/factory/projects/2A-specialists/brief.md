# Project 2A — Specialist Roles
**Account-Manager brief**

## What the client wants
Build 4 NEW specialist agents and add them to the OpenCode Factory:
1. **Tech writer** — documents the Factory and the things it builds
2. **Designer** — produces UI/design components, design systems, visual artifacts
3. **Support** — triages user/client questions, drafts responses, escalates
4. **Cybersecurity expert** — audits code/configs for security issues, threat models

## Why
The Factory currently has 16 agents. None of them specialize in:
- Writing the docs that the system needs
- Producing client-facing design work
- Handling incoming user questions
- Security review before shipping

Without these, the Factory ships things but can't document them, design them well, support users using them, or prove they're secure.

## Success criteria (Definition of Done)
- All 4 agent files exist at `C:\Users\Windows\.config\opencode\agents\`
- Each agent file is markdown with proper frontmatter (description, mode, prompt, permissions)
- Each agent is recognized by `opencode agent list` (verifiable)
- Each agent has a "kick-the-tires" test prompt that demonstrates it works
- Each agent has research-backed domain expertise baked in
- AGENTS.md routing table is updated to include all 4 new agents
- All 4 agents are tested at least once with a real prompt

## Scope
- 4 agent files only
- Routing table update in AGENTS.md
- Test runs for each
- No new skills, no new MCPs (out of scope for 2A)

## Timeline
- 1 day. This is the first end-to-end Factory project. Not rushing.

## Out of scope
- 2+ more specialists (tech writer is enough for 2A; designer, support, security added because user explicitly requested all)
- New skill files
- New MCP servers
- Changes to existing 16 agents
- Pipeline/dashboard changes

## Reference: 2026 best-practice research

### Tech writer
- AI-ready docs use consistent page templates, structured headings, examples
- "Document engineers" create documentation for BOTH humans AND AI agents
- GEO (Generative Engine Optimization) — content optimized for AI retrieval
- Reference: buildwithfern.com, fluidtopics.com 2026 trends

### Designer
- Design tokens beyond colors/spacing — typography, components, scalable systems
- Agentic Design Systems: docs built for autonomous agents assembling UIs
- Token standardization, modular architecture, multi-brand support
- Reference: designsystemscollective.com 2026, supernova.io trends

### Support
- AI-to-human handoff must not lose conversation history or force repetition
- Auto-triage: categorize requests and route to right team
- Audit common requests first, build knowledge base BEFORE automation
- Reference: bluetweak.com, kustomer.com 2026 best practices

### Cybersecurity
- OWASP AI Exchange — anchor for AI attack surfaces
- OWASP Top 10 for Agentic Security Implications (ASI) 2026
- Threat modeling for agentic AI: five-zone navigation lens
- Reference: owaspai.org, genai.owasp.org

---

**Handing off to PM for sprint decomposition.**
