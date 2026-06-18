---
name: dependency-audit
description: Runtime-enforceable dependency security rules for npm/PyPI. Gates deploy on critical/high vulnerabilities.
version: 1.0.0
type: rules
platforms: [windows, macos, linux]
triggers:
  - dependency audit
  - npm audit
  - pip audit
  - security vulnerability
  - vulnerability scan
---

# Dependency Audit Rules

## Purpose

Before any deploy, check that no package has **critical or high** severity vulnerabilities. Low/medium are informational — fix them, but don't block.

## Rule 1 — Always Audit Before Deploy

```
IF: git push to a deployable branch (main, production, etc.)
THEN: Run dependency audit
IF: audit returns critical OR high vulnerabilities
THEN: BLOCK deploy
AND: Report exact package + CVE + fix command
```

## Rule 2 — npm Audit

### For Node/JS projects

```powershell
# In project root (where package.json lives)
npm audit --audit-level=high

# Fail exit code = vulnerabilities at or above 'high'
# audit-level options: info, low, moderate, high, critical
```

**Critical/High threshold:**
```powershell
$result = npm audit --json --audit-level=high | ConvertFrom-Json
$vulns = $result.metadata.vulnerabilities
if ($vulns.critical -or $vulns.high) {
    Write-Host "[BLOCK] Critical/High vulnerabilities found:"
    $result.vulnerabilities | ConvertTo-Json -Depth 5
    exit 1
}
```

### Blocklist — Never Allow

These packages are **auto-block** regardless of severity:

| Package | Why blocked | Replacement |
|---------|------------|-------------|
| `request` | Deprecated, no security updates | `axios`, `fetch` |
| `moment` | Abandoned, timezone bugs | `date-fns`, `dayjs` |
| `lodash` < 4.17.21 | Prototype pollution | `lodash@latest` |
| `serialize-javascript` | RCE via gadget chains | `JSON.stringify` + validation |
| `vm2` | Multiple RCE CVEs | `vm` native or `isolated-vm` |

## Rule 3 — pip Audit

### For Python projects

```powershell
pip install pip-audit 2>$null
pip-audit -r requirements.txt --fail-on high,critical
```

**Python blocklist:**

| Package | Why blocked | Replacement |
|---------|------------|-------------|
| `PyCrypto` | Abandoned, multiple RCEs | `cryptography`, `pyca/cryptography` |
| `Pillow < 9.3` | Multiple CVEs | `Pillow>=9.3` |
| `requests < 2.31` | SSRF via absolute URL | `requests>=2.31` |
| `django < 4.1` | Multiple CVEs | `Django>=4.1` |
| `flask < 2.3` | Debug mode RCE | `Flask>=2.3` |
| `jinja2 < 3.1` | SSTI via sandbox escape | `Jinja2>=3.1` |

## Rule 4 — Auto-Audit in CI

```yaml
# GitHub Actions — runs on every PR
name: Dependency Audit
on: [pull_request]
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: npm audit
        if: matrix.package-manager == 'npm'
        run: npm audit --audit-level=high
        continue-on-error: false

      - name: pip audit
        if: matrix.package-manager == 'pip'
        run: pip-audit -r requirements.txt --fail-on high,critical
        continue-on-error: false
```

## Rule 5 — Audit Output Format

When audit finds issues, format the report as:

```
====================================
DEPENDENCY AUDIT REPORT
====================================
Date:     2026-05-07 14:32
Project:  palma-coin
Severity: HIGH — 1, CRITICAL — 0
====================================

[HIGH] Package: axios < 1.6.0
  CVE:      CVE-2023-45857
  Summary: Server-Side Request Forgery (SSRF)
  Fix:      npm install axios@latest
  Found in: package.json

[HIGH] Package: follow-redirects < 1.15.4
  CVE:      CVE-2023-26159
  Summary: Authorization bypass via absolute URL
  Fix:      npm install
  Found in: node_modules/axios/package.json

====================================
RESULT: 🔴 DEPLOY BLOCKED
Fix above vulnerabilities before deploying.
====================================
```

## How to Apply

1. Coordinator reads this rule before any deploy to Railway
2. Specialist runs `npm audit --audit-level=high` or `pip-audit`
3. If exit code ≠ 0 → surface report → block deploy
4. User runs fix command → re-audit → only then push

## Why

Railway deploys ship dependencies to production. A compromised package in production = data breach or RCE. npm/pip audit catches known CVEs in transitive dependencies that `package-lock.json`/`requirements.txt` silently pins.

## Source

Based on: `rules/env_security.md` + OWASP Top 10 Dependency Risks 2023
