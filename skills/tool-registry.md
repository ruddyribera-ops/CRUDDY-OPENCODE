---
name: tool_registry
description: Searchable index of all skills and tools available to agents
type: registry
version: 1.0
---

# Tool Registry

Machine-readable index of all skills, MCP tools, and system tools.
Agents use this to find the right tool for a given task.

## Skills Index

| Skill | Tags | Capabilities | Triggers |
|-------|------|-------------|---------|
| api-patterns | `api`, `rest`, `http`, `validation` | REST design, error handling, response formats | build api, create endpoint, rest route |
| auth-patterns | `auth`, `security`, `jwt`, `password` | Login, password hashing, sessions, JWT | login, auth, password hash, session |
| database-patterns | `database`, `sql`, `migration` | SQL patterns, migrations, seed data | database, sql, migration, query |
| testing-standards | `testing`, `quality` | Test structure, naming, coverage targets | test, pytest, jest, coverage |
| js-modern-patterns | `javascript`, `typescript`, `react` | ES2022+, TypeScript, React patterns | typescript, react, modern js |
| python-patterns | `python`, `fastapi`, `async` | Python 3.10+, FastAPI, Pydantic, async | python, fastapi, pydantic |
| data-analysis | `data`, `csv`, `json`, `pandas` | CSV/JSON parsing, pandas, reporting | data, csv, parse, analytics |
| deployment-patterns | `deploy`, `docker`, `railway` | Docker, Railway, containerization | deploy, docker, railway |
| realtime-patterns | `realtime`, `websocket`, `sse` | WebSocket, SSE, polling | websocket, real-time, sse |
| git-workflow | `git`, `commit`, `branch` | Conventional commits, branch naming | commit, git, branch |
| ci-cd-patterns | `ci`, `cd`, `github-actions` | GitHub Actions, pipeline patterns | ci, github actions, pipeline |
| code-review | `review`, `quality`, `security` | Security, performance, maintainability checks | review, code review, quality |
| ui-design | `ui`, `css`, `layout` | Typography, spacing, color, accessibility | ui, css, layout, design |
| security-basics | `security`, `owasp`, `xss` | Input validation, OWASP, secrets | security, xss, injection, secret |
| performance-optimization | `performance`, `bundle`, `cache` | Bundle size, lazy loading, query perf | performance, optimize, cache |
| msoffice-tools | `office`, `word`, `excel`, `pptx` | Word, Excel, PowerPoint generation | word, excel, pptx, office |
| ocr-tools | `ocr`, `tesseract`, `easyocr` | OCR, text-from-image | ocr, image, tesseract |
| desktop-manager | `desktop`, `cleanup`, `os` | Desktop scan/cleanup utility | desktop, cleanup, organize |
| minimax-pdf | `pdf`, `document`, `design` | Token-based PDF creation, form fill, reformat with design system | make PDF, generate report, create resume, fill form, reformat document |
| pptx-generator | `pptx`, `powerpoint`, `slides` | PptxGenJS slide creation, XML editing, markitdown extraction | PPT, PPTX, PowerPoint, presentation, slide, deck |
| minimax-xlsx | `xlsx`, `excel`, `spreadsheet` | XML-based Excel create/edit, formula repair, validation | spreadsheet, Excel, .xlsx, csv, financial model, formula |
| minimax-docx | `docx`, `word`, `document` | OpenXML SDK Word creation/editing, template apply, XSD validation | Word, docx, document, 报告, 合同, 公文 |
| vision-analysis | `vision`, `image`, `ocr` | MiniMax MCP image analysis, OCR, UI review, chart extraction | analyze image, describe, OCR, extract text, ui review |
| mmx-cli | `minimax`, `cli`, `media` | MiniMax CLI for text, image, video, speech, music generation | generate image, generate video, text chat, synthesize speech |

## MCP Tools

| Tool | Description | When to Use |
|------|-------------|-------------|
| context7_resolve-library-id | Get library ID for Context7 | Library not in project manifest |
| context7_query-docs | Fetch live library docs | API surface matters, version behavior differs |
| sequential-thinking | Structured step-by-step reasoning | Multi-step debugging, architecture decision, complex refactor |
| pdf-toolkit *(conditional)* | Generate PDFs from Markdown if a PDF MCP/tool is configured | Document generation, reports, invoices |
| playwright *(disabled by default)* | Headless browser automation | Enable for E2E tests, scraping, UI verification |

## System Scripts

| Script | Description | When to Use |
|--------|-------------|-------------|
| Verify-Deploy.ps1 | Post-push SHA verification | After any git push to a deployable branch |
| Init-Project.ps1 | Bootstrap new project with .opencode/ structure | New project initialization |
| Optimize-OpenCode.ps1 | Disable heavy MCPs | RAM optimization |

## Tool Contracts (Function Signatures)

### search_vibe_tools(query: string) → ranked_tool_list
**Input:** Natural language query describing a task
**Output:** Ranked list of tools with name, description, match score
**Example:** `search_vibe_tools("code review for security")` → `[{"name": "code-review", "score": 0.95}, ...]`

### scaffold_fullstack(stack: string, features: string[]) → project_skeleton
**Input:** Stack (e.g., "nextjs", "mern", "fastapi") + feature list
**Output:** Project skeleton path + generated files list
**Example:** `scaffold_fullstack("nextjs", ["auth", "api", "db"])` → creates full project in `/tmp/`

### get_style_guide(language: string) → style_guide_result
**Input:** Language name (e.g., "python", "typescript", "rust")
**Output:** `{ "url": "...", "summary": "...", "linter_config": "..." }`
**Example:** `get_style_guide("python")` → returns PEP8 + ruff config

### log_episodic_memory(summary: string, category: string) → stored_path
**Input:** Summary text + category (feedback|project|lesson)
**Output:** Path to stored memory file
**Example:** `log_episodic_memory("don't use time.sleep in tests", "feedback")` → writes to `feedback_e2e_waits.md`

---

## How to Use This Registry

1. **Skill lookup:** Match user's task to skill via `Triggers` column or route via agent routing table
2. **Tool lookup:** For system-level tasks (deploy verify, project init), use system scripts directly
3. **Contract compliance:** When adding new tools, update this registry with the tool's contract

---

*Auto-generated from skills/ directory. If `scripts/rebuild-registry.ps1` exists in your environment, run it to refresh; otherwise regenerate via the current registry script pipeline.*
