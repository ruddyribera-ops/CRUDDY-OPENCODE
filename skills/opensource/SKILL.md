---
name: opensource
description: Fetch library source code as agent context. Clone any open-source GitHub repo so the agent reads real code instead of docs. Triggers: clone a repo, fetch source code, need to understand library, reference the codebase.
When: Use when the agent needs to understand how a library works internally — better than reading docs. Run `python scripts/opensource.py clone <url>` before routing the task, then tell the agent "Reference _source/<org>/<repo>/ for context."
Do not: Clone repos unnecessarily (only when API behavior is unclear). Clone massive repos without --shallow. Forget to add _source/ to .gitignore.
Commands:
  python scripts/opensource.py clone <url> [--dir _source]
  python scripts/opensource.py list [--dir _source]
  python scripts/opensource.py clean [--dir _source]
Examples:
  python scripts/opensource.py clone https://github.com/streamlit/streamlit
  python scripts/opensource.py clone https://github.com/fastapi/fastapi
  python scripts/opensource.py list
---