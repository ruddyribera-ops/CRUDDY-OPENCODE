# OpenCode Power Setup

> ⚠️ **DEPRECATED — This repository is no longer maintained.**
>
> **The successor is [`ruddyribera-ops/CRUDDY-OPENCODE`](https://github.com/ruddyribera-ops/CRUDDY-OPENCODE).**
>
> CRUDDY-OPENCODE is the direct evolution of this template — same architecture, more agents (25 vs 10), more skills (17 standard + custom), production-grade observability, AI-output evaluation, and an adversarial deep tester that didn't exist here.
>
> If you cloned this repo, migrate by:
> ```bash
> cd ~/.config/opencode
> git remote set-url origin https://github.com/ruddyribera-ops/CRUDDY-OPENCODE.git
> git fetch origin
> git checkout release/v0.5.0   # or master after the v0.5.0 merge
> ```
>
> The full migration guide (agents, skills, plugins, env-var setup) is in the CRUDDY-OPENCODE repo.
>
> This repository is kept online as a historical reference. New users should use CRUDDY-OPENCODE.

---

# OpenCode Power Setup 🎯
*Historical description below — preserved for anyone still using this version.*

Turnkey OpenCode configuration with multi-agent orchestration, skills, memory, and automation.

⚠️ This is a template repo. Edit USER.template.md and the files in memory/ to match your identity and projects before using.

🚀 Quick Start
# 1. Clone into your OpenCode config directory
git clone https://github.com/YOUR_USER/YOUR_REPO.git ~/.config/opencode

# 2. Initialize your profile
cp USER.template.md USER.md
# Edit USER.md with your name, projects, and preferences

# 3. Validate the setup
python scripts/agent-registry.py validate
🧠 What You Get
Feature	Description
10 AI Agents	Coordinator, code-builder, bug-fixer, analyzer, explainer, architect, generator, standup, evolution, skill-manager
55 Skills	Framework patterns, security, deployment, testing, frontend design, auth, and more
7 MCPs	Filesystem, Context7, Brave Search, Playwright, Sequential Thinking, Memory, Fetch
DAG Orchestration	Task graphs for complex multi-step workflows
Challenger Rule	Safety checks before risky operations
Memory System	Persistent file-based memory between sessions
Agent Registry	python scripts/agent-registry.py report to see all agents
Mail System	Inter-agent communication via scripts/mail.py
📁 Structure
~/.config/opencode/
├── AGENTS.md              # Global agent rules
├── USER.md                # Your profile (edit this!)
├── opencode.json          # OpenCode configuration
├── agents/                # Agent definitions (10 agents)
│   ├── main-coordinator.md
│   ├── code-builder.md
│   └── ...                # One .md + .yaml per agent
├── skills/                # Domain knowledge (55 skills)
│   ├── browser-robust/
│   ├── api-patterns/
│   └── ...
├── memory/                # Persistent memory
│   ├── *.template.md      # Templates for your data
│   └── ...
├── rules/                 # Enforced rules
├── scripts/               # Automation scripts
├── workflows/             # Repeatable workflows
└── templates/             # Project scaffolding
🔧 First-Time Setup
Edit USER.md — your name, email, location, projects
Initialize memory — copy .template.md files to remove .template suffix
Set up API keys — add your OPENCODE_API_KEY, BRAVE_API_KEY, etc. as Windows env vars
Run registry check — python scripts/agent-registry.py validate
📚 Key Files
File	What to do
USER.md	Your personal profile — edit with your info
opencode.json	Model config, MCP servers, providers
agents/main-coordinator.md	Routing logic — edit triggers and routing table
workflows/constitution.template.md	Per-project rules template
scripts/mail.py	Inter-agent messaging
🧪 Validate
python scripts/agent-registry.py list      # See all agents
python scripts/agent-registry.py validate  # Check for issues
python scripts/agent-registry.py report    # Full report
📄 License
MIT — Free to use, fork, modify.
