---
name: app-scraper-tester
description: Systematic web application auditing skill — crawls, documents, and tests any web app using Playwright MCP. Produces a Blueprint.md + blueprint.json + test coverage map. Accepts target URL + optional credentials, detects SPA/MPA, maps forms/API endpoints, identifies critical paths, and generates structured audit output matching the PRIA blueprint format.
tags: [testing, web, scraper, playwright, audit]
---

# app-scraper-tester — Web Application Scraping & Audit Skill

## When to Use

**Trigger phrases (any of):** "audit this app", "scrape and document", "test this web app", "build a blueprint", "crawl this application", "map this website", "app-scraper-tester", "test the [URL]", "audit [URL]"

**What it does:** Systematically crawls a web application, discovers all routes, forms, API endpoints, and user flows, then outputs a structured blueprint (Markdown + JSON) and optional test coverage report.

**Prerequisites:** Playwright MCP must be enabled (`playwright_browser_*` tools available).

---

## Prerequisites

- **Target URL** (required)
- **Credentials** (optional — for authenticated routes)
- **Audit scope** (optional — e.g., `/admin` only)
- **Max depth** (optional, default: `5`)
- **Output path** (optional, default: `~/.config/opencode/audits/<domain>/`)

## Output Artifacts

1. **`Blueprint.md`** — Human-readable blueprint, 400+ lines: architecture, data models, page layouts, components, forms, error states, inferred endpoints, feature checklist
2. **`blueprint.json`** — Structured audit data: pages, endpoints, forms, navigation tree, critical paths, issues
3. **`test-coverage.md`** (optional) — Smoke test results per form and critical path

**Detailed output format specs with full JSON schema and Markdown template:**
→ See `references/output-format.md`

---

## Workflow Overview (5 Phases)

### Phase 1: Setup & Authentication
1. Parse inputs (URL, credentials, depth, scope, output dir)
2. Create output directory with timestamp
3. Detect auth requirement (login redirect, form fields, text patterns)
4. Authenticate (fill form, submit, wait for success)
5. Auto-recover expired sessions mid-crawl

**Detailed steps:** → See `references/crawl-phases.md#phase-1-setup--authentication`

### Phase 2: Discovery & Crawl (BFS)
1. Capture initial page state (links, forms, buttons, headings, inputs)
2. Detect SPA vs MPA via `window.*` globals
3. BFS crawl with equivalence bucketing (85% DOM similarity dedup)
4. Capture network traffic per page (XHR, fetch, static assets)
5. Extract forms and their fields

**Detailed BFS algorithm, SPA detection, and form extraction:**
→ See `references/crawl-phases.md#phase-2-discovery--crawl`

### Phase 3: Deep Analysis
1. Framework + version + router detection
2. API endpoint reconstruction from network requests (OpenAPI-style)
3. Multi-step form / wizard detection with dependency graph
4. Critical path detection (BFS from login/home)
5. Error state capture (404, 500, validation errors, auth errors)

**Detailed steps:** → See `references/crawl-phases.md#phase-3-deep-analysis`

### Phase 4: Output Generation
1. Write `Blueprint.md` following PRIA v5.4 structure (400+ lines minimum)
2. Write `blueprint.json` with all structured data
3. Write `test-coverage.md` (if Phase 5 ran)

**Output templates and schemas:** → See `references/output-format.md`

### Phase 5: Testing (Optional)
Activate when user says "run smoke tests", "test the forms", or "verify the blueprint".
1. Smoke test each form (fill, submit, check errors)
2. Test critical paths (step-by-step assertion)
3. Test error conditions (invalid credentials, missing fields, unauthorized)

**Detailed steps:** → See `references/crawl-phases.md#phase-5-testing-optional`

---

## Playwright MCP Commands

→ See `references/playwright-commands.md` for complete reference tables:

| Category | Commands |
|----------|----------|
| Navigation | `navigate`, `snapshot`, `wait_for`, `evaluate` |
| Interaction | `click`, `fill_form`, `type`, `select_option` |
| Capture | `network_requests`, `screenshot`, `console_messages` |
| State | `tabs`, `handle_dialog` |

## Example Usage

→ See `references/example-usage.md` for complete examples:
- PRIA full crawl (depth 5, with credentials)
- PRIA admin-only crawl (scope `/admin`, depth 3)
- Creativos Digitales audit

## Test Credentials (Built-in)

| App | URL | Username | Password |
|-----|-----|----------|----------|
| PRIA v5.4 | `https://priav5-production.up.railway.app/?rt=qqBXsm-...` | `admin` | `2b0n2b!123` |
| Creativos Digitales | `https://gestion.creativos-digitales.com/login` | `misterruddy@laspalmas.edu.bo` | `Capacitaciones2025` |

## Pitfalls & Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `browser_wait_for` times out | SPA not settled | Increase to 5s or wait for specific element |
| Clicking link doesn't navigate | SPA JS router | Use `browser_navigate(url)` with actual href |
| Duplicate pages | Dynamic content changes | Equivalence bucketing (85% threshold) |
| Auth session expires mid-crawl | Short session TTL | Re-authenticate and resume |
| Network requests not captured | Cached before snapshot | Clear browser cache before crawl |
| Form returns same page | Guard condition not met | Detect guards via dependency graph |
| Missing SPA routes | Lazy-loaded | Crawl all sidebar/menu items, click each tab |
| 403 on API endpoints | Auth token required | Pass credentials for authenticated calls |

## Verification

1. **Output files exist:**
   ```powershell
   Test-Path "$env:USERPROFILE\.config\opencode\audits\<domain>\<timestamp>\Blueprint.md"
   Test-Path "$env:USERPROFILE\.config\opencode\audits\<domain>\<timestamp>\blueprint.json"
   ```
2. **Blueprint.md ≥ 400 lines** for full crawl
3. **blueprint.json is valid JSON** via `ConvertFrom-Json`
4. **Pages discovered ≥ 3**
5. **All reference links resolve**

## Session Memory (After Audit)

Save key findings:
```
memory_create_entities([{
  name: "<domain>-blueprint",
  entityType: "AuditResult",
  observations: ["URL: <url>", "Framework: <framework>", "Pages: <count>", "Forms: <count>", "Endpoints: <count>", "Auth: required:optional:none", "Output: <path>"]
}])
```

## Testing Ecosystem

- **Playwright patterns**: interceptors (page.route), fixtures, visual regression, auth state (storageState)
- **API Testing**: supertest (REST), stepci (workflow), postman-to-code
- **CI**: Playwright docker image, sharding (`--shard=x/y`), webServer config
- **Reports**: Playwright HTML report, Allure, Currents, Datadog
## Do Not Use
- Unit testing of code (use testing-standards)
- UI test automation (use playwright or adaptive-ui)
- API endpoint testing (use api-patterns)
- Security penetration testing (use security-basics)
