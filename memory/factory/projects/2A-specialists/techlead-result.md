# Tech Lead Report — Project 2A (4 Specialist Agents)

**Project:** 2A-specialists
**Date:** 2026-06-08
**Owner:** tech-lead
**Status:** ✅ Scaffold + 1 reference example shipped. 3 builders can dispatch in parallel.

---

## What I built

1. **Scaffold directories** — `test-prompts/` and `reference/` created under `memory/factory/projects/2A-specialists/`.
2. **Agent template** — `reference/agent-template.md` (locked, 5-section structure, 4 builders must copy verbatim).
3. **Reference example** — `C:\Users\Windows\.config\opencode\agents\tech-writer.md` (8 KB, fully filled, ready for `opencode agent list`).
4. **Test prompt** — `test-prompts/tech-writer.md` (1 positive: GEO API doc; 1 negative: implementation refusal).
5. **AGENTS.md updated** — tech-writer row added to Identity Map (line 25), Routing Table (line 48), Handoff Rules (line 63). File: 94 → 97 lines. ✅ Under 200 cap.

## Files created (with sizes)

| File | Path | Size |
|------|------|------|
| Template | `reference/agent-template.md` | 3,720 B |
| Tech-writer | `C:\Users\Windows\.config\opencode\agents\tech-writer.md` | 8,075 B |
| Test prompt | `test-prompts/tech-writer.md` | 3,805 B |

## Verification

- `Get-ChildItem tech-writer.md` → ✅ exists, 8075 B
- `(Get-Content AGENTS.md \| Measure-Object -Line).Lines` → ✅ 97 lines (cap 200)
- Template structure matches architect's §1a design
- Tech-writer Identity & Memory: ~430 words (in 300-500 range), bakes in GEO / Diataxis / buildwithfern / fluidtopics 2026
- 12 trigger phrases, all matching routing table entry
- Workflow: 6 steps (read context → pick Diataxis → apply GEO template → write example → self-check → stamp)
- 5 Critical Rules, 6 "When NOT to act" routings, 6 MCP tools listed

## Hand-off to 4 parallel builders

**For: `code-builder-designer`, `code-builder-support`, `code-builder-cybersecurity` + 1 verifier**

1. **Use the template at `reference/agent-template.md` verbatim.** Do not add or remove sections. Do not change frontmatter keys. Do not change section order.
2. **Reference example is `C:\Users\Windows\.config\opencode\agents\tech-writer.md`** — copy its structure, swap the fill.
3. **DO NOT touch** the 16 existing agents, the global `AGENTS.md` (T6 owns that), or `agent-schema.yaml`.
4. **Bake 2026 research into Identity & Memory (300-500 words)** following the 5-paragraph structure: persona → 2026 anchor → how you operate → scars/bind spots → anti-patterns. Use brief §"Reference: 2026 best-practice research" for your domain (designer / support / cybersecurity).
5. **Test prompt goes in `test-prompts/<name>.md`** — 1 positive (in-scope) + 1 negative (out-of-scope refusal). Use architect §4 table for the exact scenarios.
6. **Permission matrix** from architect §2: designer/support get `write: allow`, cybersecurity gets `bash` READ-ONLY whitelist only.
7. **Ship target:** `<name>.md` at `C:\Users\Windows\.config\opencode\agents\` + test prompt at `test-prompts/<name>.md`. No YAML, no extra files.

## What's blocked

- None. T2-T5 parallel window is open. T6 (AGENTS.md update for designer/support/cybersecurity rows) is gated on T2-T5.

## Open questions answered

- **Compression on AGENTS.md?** Not needed. 97 lines, 103 lines of headroom.
- **Tech-writer model_tier 1 (Flash)?** Set `model: minimax/minimax-m2.7` per user spec; if it underperforms on GEO, escalate to tech-lead.

---

**Next step:** Dispatch 4 code-builders in parallel (designer / support / cybersecurity + 1 verifier). Architect brief already on their desks via `architect-result.md`.
