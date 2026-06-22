# CRUDDY-OPENCODE

> A self-improving, safety-conscious, memory-augmented OpenCode config.
> Born from a real incident. Designed for one person who never wants to lose data again.

## Origin Story

CRUDDY-OPENCODE is the direct evolution of **[opencode-power-setup](https://github.com/ruddyribera-ops/opencode-power-setup)** (the predecessor, 1 star, MIT). That repo was a turnkey template — 10 agents, 55 skills, DAG orchestration, challenger rule, memory system. CRUDDY-OPENCODE keeps all of that and adds:

- 🧬 **Self-improving autoresearch loop** (Karpathy pattern) — overnight config improvement
- 🛡️ **Incident-aware safety net** (born from the 2026-06-17 PDC destruction — see [`docs/PDC_INCIDENT_CAUTIONARY_TALE.md`](docs/PDC_INCIDENT_CAUTIONARY_TALE.md))
- 🧠 **Hybrid memory retrieval** (BM25 + vector + graph, 100% local, $0 cost)
- 🔌 **Hook automation with 90s forced-idle fallback**
- 📦 **Consolidated `factory/` single-source-of-truth structure**
- 📚 **Self-improving rule library** (4 rules, each born from a real incident)

If you're coming from opencode-power-setup: everything you knew still works. CRUDDY-OPENCODE inherits the full agent roster and skill ecosystem, then enhances it.

## v0.4.0 "Sigma" Highlights

- **21 of 21 agents implemented (100% coverage)** in `agents/` folder
- **5 P1 agents shipped**: code-explainer, code-reviewer, tech-writer, cybersecurity, architecture-advisor
- **3 P2 agents shipped**: designer, support, project-generator
- **3 P3 agents shipped**: skill-manager, standup-summary, evolution-agent
- **Canonical Handoff format** enforced across all 21 agents
- **YAML parse errors fixed** in 3 P1 files (tech-writer, cybersecurity, architecture-advisor)
- **Trigger overlaps resolved** between AGENTS.md and agent definitions
- **Audit reports** for Phase 1 QA Round 1, Phase 1 QA Fixed, Phase 2 QA, and Phase 3 QA

## What's Inside

### 🤖 Agents on Deck (21 of 21 implemented — 100% coverage)

| Agent | Role |
|-------|------|
| `account-manager` | Client-facing persona, orchestrates work via specialists |
| `main-coordinator` | Routes requests, owns the workflow, default agent |
| `code-builder` | Writes code, implements features, refactors |
| `bug-fixer` | Debug specialist — root cause analysis, error resolution |
| `code-analyzer` | Project scanner — structure, patterns, dependencies |
| `code-explainer` | Plain-language code explanation |
| `code-reviewer` | Code quality reviewer — quality gates, security, style |
| `architecture-advisor` | Tech decisions, tradeoffs, stack choice |
| `solutions-architect` | Multi-agent project scaffolding |
| `project-manager` | Sprint planning, standups, retrospectives |
| `project-generator` | Full multi-agent project generator |
| `qa-engineer` | Test plans, acceptance testing, bug triage |
| `delivery-engineer` | Deploy, CI/CD, verification |
| `tech-lead` | Technical oversight, code quality routing |
| `tech-writer` | Documentation engineer |
| `designer` | Design systems, UI/UX, visual artifacts |
| `cybersecurity` | Security audits, threat modeling, OWASP |
| `support` | Customer support triage |
| `evolution-agent` | Self-improvement, pattern detection |
| `skill-manager` | Skill creation, management, lifecycle |
| `standup-summary` | Daily status, git activity, progress |

### 🛠️ Skills Catalog (54 active + 29 archived = 83 total)

See `skills/AWESOME_INDEX.md` for the full list. Inherited from opencode-power-setup, augmented with 5 from `awesome-agent-skills` and 4 from `obra/superpowers`.

### 🔌 MCP Servers (5)

| Server | Purpose |
|--------|---------|
| `auto-browser` | Browser automation |
| `codebase-memory` | Structural code intelligence (knowledge graph queries) |
| `context7` | Library documentation lookup |
| `fetch` | HTTP fetching |
| `playwright` | Browser automation & testing |

### 🛠️ Plugins (12)

12 OpenCode JS plugins in `plugins/` covering checkpoint, sub-agent, tool guards, memory bridge, compaction survival, session title, biome formatting, and the session-start-memory hook.

### 📚 Self-Improving Rule Library (4 rules)

Each rule was born from a real incident. The library grows when the system fails:

| Rule | Source Incident | Date |
|------|----------------|------|
| `batch-file-modification-safety.md` | PDC destruction (16 files lost) | 2026-06-17 |
| `account-manager-discipline.md` | PRIA v10 demo prep (AM touched code) | 2026-06-18 |
| `sprint-methodology.md` | World Cup Budokai (6 cancellations) | 2026-06-20 |
| `common.md` | Cross-cutting patterns (audit) | 2026-06-21 |

Read these before assuming any rule is arbitrary. Each has a story.

### 📊 By the Numbers

| Component | Count |
|-----------|-------|
| Agents (implemented) | 21 of 21 |
| Skills (active) | 54 |
| Skills (archived) | 29 |
| Plugins (.js) | 12 |
| MCP servers | 5 |
| Rule files | 4 |
| Pre-flight tools | 2 (PS1 + Python) |
| Scheduled tasks | 2 (nightly autoresearch + memory watcher) |

## Quickstart (5 minutes)

### Prerequisites
- Windows 11 (Linux/macOS untested)
- OpenCode 1.17.7+
- Python 3.10+
- 4 GB free disk space (for `all-MiniLM-L6-v2` model)

### Install

```bash
# 1. Clone this repo
git clone https://github.com/ruddyribera-ops/CRUDDY-OPENCODE.git
cd CRUDDY-OPENCODE

# 2. Copy the config to OpenCode's config dir
#    (Replace <INSTALL_DIR> with your OpenCode config location)
cp -r factory/* <INSTALL_DIR>/factory/
cp opencode.json <INSTALL_DIR>/opencode.json

# 3. Copy skills to OpenCode's skills dir
cp -r skills/awesome-* <INSTALL_DIR>/skills/
cp -r skills/superpowers-* <INSTALL_DIR>/skills/

# 4. Copy the MCP server binary
mkdir -p <INSTALL_DIR>/factory/tools/codebase-memory-mcp
cp factory/tools/codebase-memory-mcp/* <INSTALL_DIR>/factory/tools/codebase-memory-mcp/

# 5. Install Python dependencies
cd <INSTALL_DIR>/factory/scripts/memory_retrieval
python -m pip install -r requirements.txt
python -m spacy download en_core_web_sm  # for graph extraction

# 6. (Optional) Register the autoresearch nightly task
# Run as Administrator:
schtasks /create /tn "OpenCode Autoresearch Nightly" /tr "powershell -ExecutionPolicy Bypass -File <INSTALL_DIR>/factory/scripts/autoresearch/nightly_run.ps1" /sc daily /st 02:00 /ru SYSTEM /rl HIGHEST /f
```

### Verify

```bash
# OpenCode boots with new config
opencode --version  # expect 1.17.7+

# Memory retrieval works
python <INSTALL_DIR>/factory/scripts/memory_retrieval/cli.py query "test" --k 3

# Autoresearch skill loads
python <INSTALL_DIR>/factory/scripts/autoresearch/iterate.py --help

# Pre-flight tool works
powershell -ExecutionPolicy Bypass -File <INSTALL_DIR>/factory/tools/preflight-snapshot.ps1 -Paths "C:\path\to\file.txt" -Operation "verify"
```

If all three return without errors, you're set.

## What's Inside (Filesystem)

```
CRUDDY-OPENCODE/
├── factory/                    # Single source of truth for system code
│   ├── scripts/autoresearch/   # Self-improving loop
│   ├── scripts/memory_retrieval/   # Hybrid BM25 + vector + graph
│   ├── hooks/                  # Session-start hook
│   ├── tools/                  # Pre-flight snapshot + MCP binaries
│   └── planning/               # Architecture specs
├── plugins/                    # 12 OpenCode JS plugins
├── rules/
│   ├── agent_rules/            # 4 rules (3 incident-derived + 1 common)
│   └── common.md               # Cross-cutting rules
├── skills/                     # 54 active + 29 archived
├── agents/                     # 21 agent definitions
├── opencode.json               # OpenCode config
├── memory/user_preferences.md.template
├── docs/PDC_INCIDENT_CAUTIONARY_TALE.md
├── SYSTEM_FLOW.md              # Master agent interaction graph
├── LICENSE
├── CHANGELOG.md
└── README.md
```

## The Story

CRUDDY-OPENCODE was built in 48 hours by a solo developer who needed an AI coding assistant that wouldn't lose his data and would get better over time. It exists because:

1. **Karpathy published `autoresearch`** and the developer realized no AI coding tool had a self-improving config loop.
2. **2026-06-17: 16 teacher planning documents were destroyed** by an in-place modification with no backups. The fix became a permanent rule.
3. **The developer kept losing context between sessions.** The memory layer was the answer.
4. **The developer wanted it all in one place.** Hence `factory/`.
5. **2026-06-21: The system had 4 incidents in 5 days.** Each one became a new rule. The library is now self-improving.

## FAQ

**Q: I used opencode-power-setup before. Will this work the same way?**
A: Yes. CRUDDY-OPENCODE is built on top of power-setup's foundation. All 21 agents and 54 inherited skills still work.

**Q: How do I get the latest v0.4.x?**
A: `git pull` after cloning. Tags: `v0.1.0`, `v0.1.1`, `v0.1.2`, `v0.2.0`, `v0.3.0`, `v0.4.0`.

**Q: What's new in v0.4.0?**
A: 100% agent coverage achieved (21 of 21 agents implemented), 11 new agents added (5 P1: code-explainer, code-reviewer, tech-writer, cybersecurity, architecture-advisor; 3 P2: designer, support, project-generator; 3 P3: skill-manager, standup-summary, evolution-agent), canonical Handoff format enforced, YAML parse errors fixed, trigger overlaps resolved.

**Q: What does the autoresearch loop actually do?**
A: Runs nightly at 2 AM, picks a config file, makes a small change, evaluates whether it improved (using a measurable metric like file_token_count), and keeps the change or reverts. Karpathy's autoresearch pattern.

**Q: What's the PDC cautionary tale?**
A: A real data loss event where 16 teacher planning documents were destroyed. Encoded into `batch-file-modification-safety.md` and `docs/PDC_INCIDENT_CAUTIONARY_TALE.md`.

**Q: Does this work on Mac/Linux?**
A: Untested. The pre-flight snapshot tools have Windows-specific paths. The autoresearch skill and memory retrieval are cross-platform. PRs welcome.

**Q: Is this safe to use on production code?**
A: Yes, with the pre-flight rule in place. But read [`docs/PDC_INCIDENT_CAUTIONARY_TALE.md`](docs/PDC_INCIDENT_CAUTIONARY_TALE.md) first. The whole point of this config is to never repeat that incident.

**Q: Why is the `factory/` directory named that?**
A: It's a metaphor. Everything that makes this config "work" is manufactured in `factory/`. The rest of OpenCode's config (plugins, rules, skills) is the assembly line.

**Q: How do I add my own skills?**
A: Drop them in `skills/your-skill-name/`. They'll auto-load. If you want to follow a TDD-style authoring process, see `skills/superpowers-writing-skills/`.

**Q: How does autoresearch know what to improve?**
A: It doesn't, autonomously. You point it at a target file with `--target` and a measurable metric with `--metric`. Example: `python factory/scripts/autoresearch/iterate.py --target rules/your-rule.md --metric file_token_count --budget 5m`. See the skill's `SKILL.md`.

**Q: Can I disable autoresearch?**
A: Yes — `schtasks /delete /tn "OpenCode Autoresearch Nightly" /f`. Or just don't register it. The skill itself is opt-in per-run.

**Q: Why MIT?**
A: Because OpenCode's source is MIT. I want my config to be as portable as the tool itself.

## Contributing

Issues and PRs welcome. Read [`docs/PDC_INCIDENT_CAUTIONARY_TALE.md`](docs/PDC_INCIDENT_CAUTIONARY_TALE.md) before submitting — it explains the design ethos.

## License

MIT © 2026 Ruddy Ribera
