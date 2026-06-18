# CRUDDY-OPENCODE

> A self-improving, safety-conscious, memory-augmented OpenCode config.
> Born from a real incident. Designed for one person who never wants to lose data again.

## What It Is

CRUDDY-OPENCODE is a custom configuration for [OpenCode](https://opencode.ai/) that turns it into a self-improving, memory-augmented coding assistant. Every piece is local, every batch file operation is preceded by an automatic snapshot, and the system runs an overnight loop that quietly improves the config itself.

**Distinctive features:**
- 🧬 **Self-improving autoresearch loop** — Karpathy's `autoresearch` pattern, applied to your config files. Every night at 2 AM, the system picks a config file, makes a small change, evaluates whether it improved, and keeps it or reverts. Over time, the config gets better without you touching it.
- 🛡️ **Incident-aware safety net** — A real data loss event (2026-06-17, 16 teacher planning documents destroyed) is encoded into a permanent rule that prevents the same failure mode. See [`docs/PDC_INCIDENT_CAUTIONARY_TALE.md`](docs/PDC_INCIDENT_CAUTIONARY_TALE.md).
- 🧠 **Hybrid memory retrieval** — BM25 + vector embeddings + knowledge graph, all running locally on `sentence-transformers/all-MiniLM-L6-v2`. 87 indexed memories at v0.1.0, queryable in ~1 second. $0 cost.
- 🔌 **Hook automation** — OpenCode JS plugin fires on session lifecycle events, with a 90-second forced-idle fallback so it works even when OpenCode's event delivery is unreliable.
- 📦 **Consolidated structure** — All system code lives under `factory/`. No scattered files.

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

## What's Inside

```
CRUDDY-OPENCODE/
├── factory/                    # All system code (single source of truth)
│   ├── scripts/
│   │   ├── autoresearch/       # Self-improving loop (Karpathy pattern)
│   │   └── memory_retrieval/   # Hybrid BM25 + vector + graph retrieval
│   ├── hooks/                  # Session-start hook scripts
│   ├── tools/                  # Pre-flight snapshot + MCP binaries
│   ├── planning/               # Architecture specs (mem-retrieval, mem-v2)
│   └── docs/                   # HOOKS.md, ARCHITECTURE.md
├── plugins/                    # OpenCode JS plugins (10 total)
├── rules/
│   └── agent_rules/
│       └── batch-file-modification-safety.md  # Born from PDC incident
├── skills/
│   ├── awesome-*/              # 5 skills from awesome-agent-skills
│   └── superpowers-*/          # 4 skills from obra/superpowers
├── opencode.json               # OpenCode config (with env-var key refs)
├── memory/
│   └── user_preferences.md.template  # ← copy to user_preferences.md locally
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

## FAQ

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