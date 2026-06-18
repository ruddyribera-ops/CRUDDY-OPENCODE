## Research-First Gates (Run BEFORE Routing)

**BEFORE routing, always check if task needs research first:**

| Condition | Action |
|-----------|--------|
| User mentions unfamiliar library or tool | Research before routing: use context7 or fetch for docs |
| Error message mentions obscure package | Check library docs via context7 before routing to bug-fixer |
| Architecture request with multiple tech options | WebSearch comparison articles first |
| Security best-practice question | Read security-basics skill first |
| Deployment/platform choice | Research current Railway pricing/caps if deploy-related |
| Any "what's the best X for Y" | WebSearch current comparisons (not memory) |

### Opensource Auto-Fetch (Silent)

When the task mentions a well-known open-source library (streamlit, fastapi, react, express, sqlalchemy, pytest, etc.) and the project doesn't already have `_source/<org>/<repo>/`, run `python scripts/opensource.py clone <url>` in the background.

Pass this to the specialist: "Source code for {library} is available at _source/{org}/{repo}/ — reference it when API behavior is unclear."

**Skip if:** the library is trivial (os, sys, pathlib), or already referenced correctly elsewhere in the project. Don't fetch more than 2 libraries per task.

**Known library mapping (auto-detect):**
| Library | GitHub URL |
|---------|-----------|
| streamlit | https://github.com/streamlit/streamlit |
| fastapi | https://github.com/fastapi/fastapi |
| react | https://github.com/facebook/react |
| express | https://github.com/expressjs/express |
| sqlalchemy | https://github.com/sqlalchemy/sqlalchemy |
| pytest | https://github.com/pytest-dev/pytest |
| httpx | https://github.com/encode/httpx |
| pydantic | https://github.com/pydantic/pydantic |
| jinja2 | https://github.com/pallets/jinja |
| click | https://github.com/pallets/click |
| next.js | https://github.com/vercel/next.js |
| vue | https://github.com/vuejs/core |
| vite | https://github.com/vitejs/vite |

**Implementation:** Run `python scripts/opensource.py clone <url>` via bash, capture result, prepare context. Do NOT inform the user. Just pass the path to the specialist.

### Browser Automation — Tool Decision

| Condition | Use | Why |
|-----------|-----|-----|
| Localhost/dev/staging site, standard UI testing | Playwright MCP | Zero setup, native MCP tools |
| Site has Cloudflare/Turnstile/bot detection | browser-robust (`scripts/browser.py`) | CloakBrowser stealth pass |
| Unknown site scraping, adaptive selectors needed | browser-robust | Scrapling handles redesigns |
| Playwright MCP gets blocked/times out | Fallback ↑ browser-robust | Belt-and-suspenders |

**Full decision doc:** `rules/browser_tool_decision.md`

**Implementation:** If research is needed, run it BEFORE routing. Pass the findings to the specialist as context. Don't route and let the specialist rediscover.

