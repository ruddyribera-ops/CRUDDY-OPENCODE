---
name: adaptive-ui
description: Playwright-based DOM survival patterns for dynamic UIs (Streamlit, FastAPI+HTMX, React). Handles cold starts, DOM mutations, and selector fragility.
tags: [frontend, ui, testing, playwright]
---

# Adaptive UI — DOM Survival Patterns

## When to Use
- UI tests failing due to dynamic elements or timing issues
- Playwright selectors breaking after DOM changes
- Cold start timeouts in Streamlit/FastAPI apps
- Tests that work locally but flake in CI

## Do Not Use
- Static page testing with stable selectors (use standard Playwright)
- Unit testing of business logic
- API-only backend testing
- Performance or load testing

## Problem
Dynamic UIs regenerate their DOM on every interaction:
- **Streamlit**: entire script reruns on every widget interaction
- **HTMX**: partial DOM swaps without full page reload
- **React/Vue**: virtual DOM diffing can relocate elements
- **Cold starts**: elements don't exist until backend is fully initialized

Fixed `time.sleep()` timers flake under load or on cold starts.

## Core Principle
**Wait for state, not for time. Wait for evidence, not for assumption.**

## Rules

### Rule 1 — Never time.sleep in UI tests
Use `wait_for_selector` with timeout instead. See `references/patterns.md`.

### Rule 2 — Use anchored selectors, not positional ones
Find by stable content anchor (`has-text`, `text-is`) rather than nth-child or array index.

### Rule 3 — Streamlit-specific patterns
- Login: wait for form elements with stable selectors
- Cold start: wait for `.stApp` then route-specific anchor (20-40s timeout)
- After widget interaction: wait for rerun to complete (detect hide/show cycle)

### Rule 4 — Adaptive element finding
When selectors break, use content-anchored `has-text()` instead of DOM paths.

### Rule 5 — Detect DOM mutation
Wait for DOM stability (count stops changing for N ms) rather than fixed time.

### Rule 6 — Railway-specific cold start
Configure timeout per environment. Railway cold start = 20-45s for Streamlit.

See `references/patterns.md` for full Python implementations of all rules.

## Verification
```powershell
cd $env:TEMP
python -m playwright install chromium --with-deps 2>$null
python -c "
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=$true)
    page = browser.new_page()

    # Test cold start
    page.goto('https://your-streamlit-app.railway.app')
    page.wait_for_selector('.stApp', timeout=45000)

    # Test login flow
    page.fill('input[type=\"text\"]', 'user@school.bo')
    page.fill('input[type=\"password\"]', 'secret123')
    page.click('button:has-text(\"Ingresar\")')
    page.wait_for_selector('.stMainBlockContainer', timeout=20000)

    browser.close()
    print('OK')
"
```

## Common Pitfalls

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| `time.sleep(5)` | Too slow warm, too fast cold | `wait_for_selector` with timeout |
| `page.locator().first` | Order changes on rerender | Content-anchored selectors |
| Hardcoded nth-child paths | DOM structure shifts | `has-text()` or `has()` |
| Click then immediate assert | Rerun in progress | Add wait between action and assert |
| One timeout for all envs | Railway cold start = 45s | Configurable timeout per env |

## Integration
- **Load `feedback_e2e_waits.md`** before writing any UI test
- **Load `reference_streamlit_login.md`** for stable selectors per project
- **Load `feedback_playwright_eaccess.md`** if browser fails to spawn (Windows Defender)
