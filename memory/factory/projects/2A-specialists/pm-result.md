# Sprint — Project 2A (4 Specialist Agents)

**Started:** 2026-06-08
**Appetite:** 1 day (8 hours of engineering work)
**Hill position:** climbing
**Brief:** `brief.md` (4 new specialists: tech-writer, designer, support, cybersecurity)

---

## Sprint goal

Ship 4 production-quality specialist agent files (markdown prompt + YAML manifest + kick-the-tires test) recognized by `opencode agent list`, with the AGENTS.md routing table updated.

---

## Tasks

### 1. [PICKED] Solutions Architect — Shared agent template & spec
- **Owner:** `solutions-architect`
- **Deliverable:** `memory/factory/projects/2A-specialists/architecture.md`
- **Acceptance:**
  - Defines shared `.md` frontmatter schema (name, description, when, do not)
  - Defines shared `.yaml` manifest schema (matches `agent-schema.yaml`: name, version, description, model_tier, role, capabilities, skills_used, guardrails, trigger_keywords)
  - Picks model_tier per specialist (writer=1, designer=2, support=2, security=3)
  - Picks role enum per specialist (writer=generator, designer=generator, support=coordinator, security=analyzer)
  - Specifies minimum 3 capabilities + 3 guardrails per agent
  - Includes a "kick-the-tires" test prompt template
- **Dependencies:** none — runs FIRST, gates everything

### 2. [QUEUED] code-builder — Tech Writer agent
- **Owner:** `code-builder`
- **Deliverables:**
  - `agents/tech-writer.md`
  - `agents/tech-writer.yaml`
  - `memory/factory/projects/2A-specialists/test-prompts/tech-writer.txt`
- **Acceptance:** schema-valid, GEO/document-engineer 2026 expertise baked in, 3+ capabilities, 3+ guardrails, trigger keywords match routing table
- **Dependencies:** Task 1

### 3. [QUEUED] code-builder — Designer agent
- **Owner:** `code-builder`
- **Deliverables:** `agents/designer.md`, `agents/designer.yaml`, `.../test-prompts/designer.txt`
- **Acceptance:** design-tokens / agentic design systems 2026 expertise baked in, 3+ capabilities, 3+ guardrails
- **Dependencies:** Task 1 (parallel with 2, 4, 5)

### 4. [QUEUED] code-builder — Support agent
- **Owner:** `code-builder`
- **Deliverables:** `agents/support.md`, `agents/support.yaml`, `.../test-prompts/support.txt`
- **Acceptance:** AI-to-human handoff, auto-triage, knowledge-base 2026 expertise, 3+ capabilities, 3+ guardrails
- **Dependencies:** Task 1 (parallel with 2, 3, 5)

### 5. [QUEUED] code-builder — Cybersecurity agent
- **Owner:** `code-builder`
- **Deliverables:** `agents/cybersecurity.md`, `agents/cybersecurity.yaml`, `.../test-prompts/cybersecurity.txt`
- **Acceptance:** OWASP AI Exchange + Top 10 ASI + threat modeling 2026 expertise, 3+ capabilities, 3+ guardrails
- **Dependencies:** Task 1 (parallel with 2, 3, 4)

### 6. [QUEUED] code-builder — Update AGENTS.md routing table
- **Owner:** `code-builder`
- **Deliverable:** updated `AGENTS.md` (Identity Map + Intent → Agent Routing Table rows for all 4 new agents)
- **Acceptance:** all 4 new agents appear in both tables with correct role, trigger words; line count stays ≤200
- **Dependencies:** Tasks 2, 3, 4, 5 (needs the trigger keywords)

### 7. [QUEUED] code-reviewer — Review all 4 agent files
- **Owner:** `code-reviewer`
- **Deliverable:** `memory/factory/projects/2A-specialists/review-report.md`
- **Acceptance:**
  - All 4 .md + 4 .yaml files pass `agent-schema.yaml` validation
  - Each has 3+ capabilities, 3+ guardrails
  - Each has a working kick-the-tires test prompt
  - AGENTS.md routing is consistent with trigger_keywords in each manifest
  - No overlap or contradictions between agents
- **Dependencies:** Task 6

### 8. [QUEUED] delivery-engineer — Verify & hand off to AM
- **Owner:** `delivery-engineer`
- **Deliverable:** `memory/factory/projects/2A-specialists/handoff.md` + `opencode agent list` output captured
- **Acceptance:**
  - `opencode agent list` shows all 4 new agents
  - Each agent has been smoke-tested with its kick-the-tires prompt (output captured)
  - 90-second walkthrough of running each agent
  - Bundle handed to AM
- **Dependencies:** Task 7

---

## Dependency graph (DAG)

```
T1 Architect
   │
   ├──► T2 Tech Writer ─────┐
   ├──► T3 Designer    ─────┤
   ├──► T4 Support     ─────┼──► T6 AGENTS.md update ──► T7 code-reviewer ──► T8 Delivery
   └──► T5 Cybersecurity ───┘
```

**Parallelism window:** T2 / T3 / T4 / T5 (4 simultaneous code-builders)
**Critical path:** T1 → T2..T5 → T6 → T7 → T8 (~7-8 hours)

---

## Risk register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Architects design and builders drift on schema fields | High | All 4 builders must read architecture.md and copy the same template structure |
| YAML manifest fields don't match `agent-schema.yaml` | High | Run schema validation in T7 review |
| `opencode agent list` rejects a file (malformed frontmatter, missing required key) | Medium | Test once after T2 ships first agent; share learning with T3/T4/T5 |
| Research references in brief are 2026-best-practice but may need freshness check | Low | Use context7 to verify any framework name; default to stable, well-known references |
| AGENTS.md exceeds 200-line cap after 4 new rows | Low | Compress existing rows if needed; builder to verify count before commit |

---

## Definition of done (sprint)

- [ ] All 4 agents exist as `.md` + `.yaml` in `C:\Users\Windows\.config\opencode\agents\`
- [ ] All 4 pass `agent-schema.yaml` validation
- [ ] `opencode agent list` shows all 4
- [ ] Each has a kick-the-tires test prompt that has been executed (output saved)
- [ ] `AGENTS.md` updated (Identity Map + Routing Table), still ≤200 lines
- [ ] `code-reviewer` report filed with no blocking issues
- [ ] Delivery handoff bundle (`handoff.md`) ready for AM
- [ ] No new skills, no new MCPs, no changes to the 16 existing agents

---

## Today's focus

- **Now:** Solutions Architect designs shared template (T1) — gate for the rest
- **After T1 unblocks:** dispatch T2/T3/T4/T5 in parallel

## Blockers

- (none yet)

## Tomorrow's focus

- T6 routing table update
- T7 review
- T8 delivery handoff to AM

## Hill position

- **Start of day:** climbing (architecture unknown)
- **End of T1:** top of the hill
- **T2-T5:** downhill (parallel execution)
- **T6-T8:** finishing
