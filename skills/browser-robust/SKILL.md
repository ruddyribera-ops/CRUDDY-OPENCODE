---
name: browser-robust
description: CloakBrowser + Scrapling hybrid — reliable browser automation that handles bot detection, site changes, and CDP flakiness. Use instead of Playwright MCP for any browser task. Triggers: navigate a site, click something, fill a form, scrape a page, take a screenshot, extract data from a page, click button, fill input, browser automation, web scraping, cloudflare bypass, turnstile bypass.
When: Use for any browser task where Playwright is flaky or gets blocked. CloakBrowser passes Cloudflare/Turnstile/bot detection. Scrapling adaptive selectors survive site redesigns.
Do not: Use for simple HTTP requests (use fetch instead). Use for PDF generation (use write_pdf). Use for desktop app automation (use desktop-commander).
Commands:
  python $CONFIG/scripts/browser.py navigate <url> [--timeout N]
  python $CONFIG/scripts/browser.py click <selector> [--timeout N]
  python $CONFIG/scripts/browser.py type <selector> <text>
  python $CONFIG/scripts/browser.py screenshot [path]
  python $CONFIG/scripts/browser.py html
  python $CONFIG/scripts/browser.py text [selector]
  python $CONFIG/scripts/browser.py adaptive <selector>
  python $CONFIG/scripts/browser.py extract <prompt>
  python $CONFIG/scripts/browser.py cookies [--domain X]
  python $CONFIG/scripts/browser.py reset
  python $CONFIG/scripts/browser.py close
Returns: JSON with {"ok": true, "data": ...} or {"ok": false, "error": "..."}
Notes:
  - Browser persists between commands (stateful session). Call reset() to get a fresh context.
  - All commands return JSON — parse the "data" field for results.
  - adaptive selector returns texts from matching elements (up to 10).
  - screenshot saves to the path provided (default: screenshot.png in cwd).
  - navigate defaults to 30s timeout, click to 15s, type to 10s.
  - cloakbrowser auto-downloads stealth Chromium (~200MB) on first launch.
  - Cloudflare and Turnstile are bypassed automatically by CloakBrowser.
Skills: security-basics, performance-optimization
---