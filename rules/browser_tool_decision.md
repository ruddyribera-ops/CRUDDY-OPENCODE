# Browser Tool Decision — Playwright MCP vs browser-robust (CloakBrowser + Scrapling)

## Decision: Default to Playwright MCP, fallback to browser-robust

| Criterion | Playwright MCP | browser-robust |
|-----------|---------------|----------------|
| Setup | Zero (MCP auto-start) | Needs `scripts/browser.py` + ~200MB stealth Chromium download on first run |
| Bot detection bypass | No (standard browser) | Yes (CloakBrowser passes Cloudflare/Turnstile) |
| Live site | Full (click, type, snapshot, fill_form) | CLI commands via browser.py |
| Selector adaptation | No | Yes (Scrapling adaptive selectors survive redesigns) |
| Dev/localhost | Yes | Also works locally |
| Screenshot | Built-in | Via CLI |
| Integration | Native MCP tools (no parsing) | JSON CLI responses (must parse) |
| Cold start | Instant | First-run: ~200MB download |

## When to use which

**Use Playwright MCP (default) when:**
- Browsing localhost, dev server, or staging
- Performing standard UI testing (click, type, navigate, screenshot)
- Taking screenshots for documentation
- Filling forms on known sites
- Any interaction where bot detection is not a concern

**Use browser-robust (fallback/specialized) when:**
- Target site has Cloudflare, Turnstile, or other bot detection
- Site selectors keep changing (use adaptive selector mode)
- Playwright MCP gets blocked, times out, or returns blank pages
- Scraping data from third-party sites with aggressive anti-bot measures
- Site returns HTTP 403, 503, or challenge page

**Checklist:**
1. [ ] Is the target URL behind Cloudflare/Turnstile? → browser-robust
2. [ ] Is this a dev/localhost/staging site? → Playwright MCP
3. [ ] Are we scraping an unknown third-party site? → browser-robust
4. [ ] Is this a simple screenshot/form-fill on a known site? → Playwright MCP
5. [ ] Did Playwright MCP fail/get blocked? → Fallback to browser-robust

## Route Integration

In `main-coordinator.md` Research-First Gates section:

**Browser automation check:**
- If target involves web scraping, bot-protected sites, or Cloudflare → route with "Use browser-robust (CloakBrowser + Scrapling) via `scripts/browser.py`"
- Otherwise → route with "Use Playwright MCP"
