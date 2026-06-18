# Crawl Phases — Detailed Steps

## Phase 1: Setup & Authentication

### 1.1 Parse Inputs
Collect: `TARGET_URL`, `USERNAME`/`PASSWORD` (optional), `MAX_DEPTH` (default: 5), `AUDIT_SCOPE` (optional), `OUTPUT_DIR` (default: `~/.config/opencode/audits/<domain>/`)

### 1.2 Create Output Directory
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.config\opencode\audits\<domain>\<timestamp>" -Force
```
Structure:
```
audits/<domain>/<timestamp>/
├── Blueprint.md
├── blueprint.json
└── test-coverage.md
```

### 1.3 Detect Auth Requirement
Navigate to target URL, capture snapshot, check for login indicators:
- Redirect to `/login`, `/signin`, `/auth`
- Presence of username/password fields
- Text patterns: "login", "sign in", "acceder", "autentic"

### 1.4 Authenticate (if credentials provided)
1. Detect login form fields via snapshot
2. Fill credentials with `playwright_browser_fill_form`
3. Click submit button
4. Wait for navigation (detect dashboard/home text)
5. Detect auth errors via snapshot for `st.error`, `.error`, red text
6. Playwright MCP handles cookies automatically

### 1.5 Auth Auto-Recovery (for long crawls)
If session expired mid-crawl (patterns: "sesión expirada", "session expired"):
- Re-authenticate using stored credentials
- Resume crawl from interrupted page

## Phase 2: Discovery & Crawl

### 2.1 Capture Initial Page State
Extract: all links, forms, buttons, headings (h1-h6), inputs

### 2.2 Detect SPA vs MPA
Use `playwright_browser_evaluate` to check for framework globals:
```javascript
return {
  react: !!window.React,
  vue: !!window.Vue,
  angular: !!document.querySelector('[ng-version]'),
  svelte: !!window.__sveltekit,
  streamlit: !!window.streamlit,
  nextjs: !!window.__NEXT_DATA__
};
```
- **SPA:** Use `browser_wait_for` after every interaction
- **MPA:** Standard navigation with `browser_navigate`

### 2.3 Build Navigation Tree (BFS)
Maintain queue of `{url, parent, label, depth}`. For each page at depth < MAX_DEPTH:
1. Navigate (click if SPA, navigate if MPA)
2. Wait for network idle
3. Capture snapshot + network requests
4. Extract same-origin links
5. Apply equivalence bucketing (85% DOM similarity dedup)
6. Enqueue unvisited links

### 2.4 Capture Network Traffic
Track all XHR/fetch, static assets, redirect chains per page.

### 2.5 Form Extraction
For each discovered form: input fields, select options, radio/checkbox groups, submit button, hidden fields, action/method, validation attributes.

## Phase 3: Deep Analysis

### 3.1 Framework Detection
Framework + version + router detection via `browser_evaluate`.

### 3.2 API Endpoint Reconstruction
From network requests, reconstruct OpenAPI-style endpoints grouped by resource (auth, CRUD, upload, export).

### 3.3 Multi-Step Form / Wizard Detection
Track form submissions across pages to detect multi-step flows. Build form dependency graph:
```
Form A (upload) → enables Form B (generate) → enables Tabs C (slides, quiz)
```

### 3.4 Critical Path Detection
BFS from login/home to identify key journeys:
- Login → Dashboard
- Dashboard → key feature
- Admin-only paths
- Data modification paths

### 3.5 Error State Capture
Trigger then snapshot: 404, 500, validation errors, auth errors.

## Phase 4: Output Generation

### 4.1 Blueprint.md
Generate Markdown following PRIA v5.4 structure. Minimum target: 400+ lines.

### 4.2 blueprint.json
Structured JSON with: pages, endpoints, forms, navigationTree, criticalPaths, issues.

### 4.3 test-coverage.md (optional)
Smoke test results per form and critical path.

## Phase 5: Testing (Optional)

Activate when user says "run smoke tests", "test forms", or "verify blueprint".

### 5.1 Smoke Test Each Form
Navigate, fill, submit, check errors.

### 5.2 Test Critical Paths
Follow each step in sequence, assert expected state.

### 5.3 Test Error Conditions
Invalid credentials, missing fields, unauthorized access, 404 handling.
