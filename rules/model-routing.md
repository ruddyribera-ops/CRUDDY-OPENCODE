## Model Tier Routing (Three-Model Setup via OpenCode Go)

**Configured for DeepSeek V4 + MiniMax M2.7 default via OpenCode Go ($5/$10/mo subscription). M3 reserved for on-demand user invocation. This is tier-based selection, NOT fallback-on-failure.**

### Tier Mapping

| Tier | Score | Model | Context | Use |
|------|-------|-------|---------|-----|
| **1 - Simple** | 0-3 | `opencode-go/deepseek-v4-flash` | **1M tokens** | reads, scans, typos, one-liners, quick wins |
| **2 - Medium** | 4-6 | `opencode-go/deepseek-v4-pro` | **1M tokens** | refactors, debug, multi-file, heavy lifting |
| **3 - Complex** | 7-10 | `minimax/minimax-m2.7` | **200K+ tokens** | architecture, full-stack, new project, coordinator |

### Context Window Strategy

**DeepSeek (1M tokens) vs MiniMax (200K tokens):**
- Use **DeepSeek v4-flash** for: large codebase scans (>100 files), full skill directory reads, bulk analysis, anything MiniMax would struggle with
- Use **DeepSeek v4-pro** for: architecture decisions, complex multi-file refactors, debugging chains
- Use **MiniMax M2.7** for: fast routing, daily coordination, simple edits

**Overflow rule:** When task exceeds MiniMax's 200K limit → auto-escalate to DeepSeek v4-flash.

### Keyword Detection (inline)

Use these keywords to classify WITHOUT external function call:

**Tier 1 keywords (→ opencode-go/deepseek-v4-flash):** read, show, list, typo, what is, where is, view, cat, type (file)

**Tier 2 keywords (→ opencode-go/deepseek-v4-pro):** refactor, debug, fix bug, analyze, review, test, multiple files, across

**Tier 3 keywords (→ minimax/minimax-m2.7):** design, architecture, microservices, full-stack, from scratch, new project, create app, implement, generate app, scaffold

### Context hints you can extract from the conversation:
- `fileCount`: number of files mentioned
- `taskType`: read/write/edit/refactor/debug/architect/generate
- `isNewProject`: "new project", "from scratch", "generate app"
- `isFullStack`: mentions frontend + backend
- `isArchitectureDecision`: "architecture", "design pattern", "strategy"
- `isMultiDomain`: mentions 2+ domains (auth + DB + API, etc.)
- `hasMigration`: "migration", "migrate", "upgrade"
- `hasDeployment`: "deploy", "docker", "kubernetes", "railway"

### M2.7 Task Scaffolding (auto-apply)

When routing to specialist on MiniMax M2.7, handover MUST include:
- Explicit file paths (never "somewhere in the codebase")
- Code pattern to follow (never "figure out the approach")
- ONE edge case to test before marking done
- Verification command (curl, test, browser check)
- Target: ~3K tokens maximum (compressed format per `rules/handover_format.md`)

Before every M2.7 handover, prepend:
> "Before implementing, state ONE alternative approach and why you chose this one."

After specialist completes, apply Verification Depth gate (see `rules/verification_depth.md`). Reject Tier 0 completions.

Load `memory/feedback_m2_compensation.md` at session start when using M2.7 (see AGENTS.md loading order step 0).

### M3 On-Demand (Manual Override)

**M3 (`minimax/minimax-m3`) is NOT used automatically.** It is reserved for explicit user invocation when the user says something like:
- "use M3 for this"
- "switch to M3"
- "escalate to M3"
- "burn the quota for this"

**Why:** M3 burns through API quota fast. Default to M2.7 for everything.

**How to invoke:** Set the agent's `model:` field (in its .md frontmatter) to `minimax/minimax-m3`, or specify it in the handover prompt. The provider config in `opencode.json` already has M3 listed (line 45-47), so it works.

**Quarantine:** M3 should not appear in any tier-based routing table. If a task genuinely needs M3, the user will say so.

