---
name: differential-review
description: Security-focused differential code review — comparing changes against baseline, identifying security regressions, supply-chain risks, and OWASP ASI 2026 threats. Triggers: PR review, differential review, security regression, supply chain, CVE, OWASP, blast radius, code diff, blast radius assessment.
---

# Differential Review

## When to use this

Load this skill when reviewing a pull request, merge request, or any code diff for security implications. This skill is for any reviewer examining changes — not just security specialists.

---

## Core Principles

1. **The diff is the attack surface** — Every line added or changed is a potential vulnerability. New code is higher risk than modified code.

2. **Blast radius assessment before correctness** — Before checking if the change is correct, check how bad it would be if it were wrong. A bug in an auth module is worse than a bug in a logging module.

3. **Supply chain changes require extra scrutiny** — New dependencies, version bumps, and changes to build configuration are high-risk. A malicious dependency can exfiltrate secrets or compromise the build.

4. **Security regressions are the primary concern** — A new feature that weakens auth, exposes internal endpoints, or adds injection points is worse than a feature that has a bug.

5. **Review the tests too** — Security-relevant changes without tests are suspect. Tests that pass for the happy path but not for adversarial inputs are a red flag.

6. **Two-question security review** — (1) If this change is exploited, what is the maximum damage? (2) Is that damage acceptable?

7. **Small changes are not necessarily low-risk** — A one-line change can introduce a critical vulnerability (e.g., disabling auth, adding `?debug=true`).

---

## Patterns

### Blast Radius Assessment Matrix

| Change Type | Risk Level | Examples |
|------------|------------|---------|
| New endpoint exposed | HIGH | Adding a public API route, removing auth decorator |
| Auth/permission change | CRITICAL | Modifying role checks, changing session handling |
| New dependency added | HIGH | New npm package, pip package, Docker image |
| Version bump of dep | MEDIUM | Updating a transitive dependency |
| File upload handling | HIGH | New upload endpoint, file type validation |
| User input handling | HIGH | New query param, header, body field |
| Encryption/crypto change | CRITICAL | Changing how secrets are stored, new crypto usage |
| Config/env change | HIGH | New env var that changes auth behavior |
| Network/listening change | CRITICAL | Binding to 0.0.0.0, new ingress rule |
| Logging/metrics change | LOW | Adding debug logs, new metrics |

### Supply Chain Security Review

```bash
# When a dependency is added or updated:

# 1. Check the diff: package.json, requirements.txt, go.mod, etc.
#    New packages need the most scrutiny

# 2. Verify package integrity (npm)
npm audit --audit-level=high
# Check for: malware packages, typosquatting, known CVEs

# 3. Check the package's own dependencies (lightly)
#    A direct dependency with 500 transitive dependencies is a large attack surface

# 4. Verify the package is still maintained
#    Last commit date, number of maintainers, issue resolution time

# 5. Check for malicious patterns in the package
#    Does it run scripts during install?
#    Does it access the network during build?
#    Does it read files outside node_modules?

# 6. For Docker images: verify the base image
#    Use specific version tags, not :latest
#    Check for known CVEs in the base image
docker scout cves image:alpine:3.19
```

### Auth and Permission Change Review

```python
# When reviewing auth-related changes, ask:
# 1. Can unauthenticated users access this?
# 2. Can users access resources they shouldn't?
# 3. Does this break any existing permission model?
# 4. Is the new auth mechanism as strong as the old one?

# RED FLAGS in auth changes:

# 1. Removing @require_auth decorator
# - diff: -@app.route("/admin")
# +@app.route("/admin")  # Auth removed!
# Impact: CRITICAL — admin endpoint now public

# 2. Weakening role check
# -if user.role == "admin":
# +if user.role in ["admin", "editor"]:
# Impact: HIGH — editors now have admin access

# 3. Bypassing auth for "debugging"
# +if os.environ.get("DEBUG") == "true":
# +    return {"secret": "..."}  # Debug mode exposes secrets
# Impact: CRITICAL — debug mode can be enabled in production

# 4. New public endpoint with sensitive operations
# +@app.route("/api/export-all-data")
# Impact: HIGH — any authenticated user can export all data

# 5. Removing rate limit on auth endpoint
# -@rate_limit("5 per minute")
# +# No rate limit
# Impact: HIGH — enables credential stuffing
```

### SQL Injection Review in Diffs

```python
# When reviewing SQL-related changes:

# SAFE: Parameterized query
cursor.execute(
    "SELECT * FROM users WHERE email = %s",
    (email,)  # Safe — email is a parameter, not interpolated
)

# DANGEROUS: String interpolation in SQL
cursor.execute(
    f"SELECT * FROM users WHERE email = '{email}'"
    # Dangerous — if email = "'; DROP TABLE users; --"
    # This becomes: SELECT * FROM users WHERE email = ''; DROP TABLE users; --'
)

# Pattern match for dangerous SQL:
# Look for: f", ', .format(), %%, + variable in SQL strings
# Especially in: raw(), extra(), find_by_sql(), @query, rawQuery()
```

### Input Validation Review

```python
# New endpoints or parameters need validation review:

# Ask: What user input is accepted?
# Ask: How is it validated?
# Ask: Where is it used (SQL, file system, exec, HTML output)?

# RED FLAGS:

# 1. No validation on new input
# +@app.route("/api/search")
# +def search(q):  # No validation of q
# +    return db.query(f"SELECT * FROM items WHERE name = '{q}'")
# Impact: CRITICAL — SQL injection

# 2. Weak validation that can be bypassed
# def validate_email(email):
#     return "@" in email  # Too weak — "a@a" passes but is valid
# Impact: MEDIUM — allows some invalid emails

# 3. File path without sanitization
# +@app.route("/download")
# +def download(filename):
# +    return send_file(f"/uploads/{filename}")
# Impact: HIGH — path traversal: filename = "../../etc/passwd"
```

### OWASP ASI 2026 Threat Categories

| Threat | What to Check |
|--------|---------------|
| **LLM01: Prompt Injection** | New code that processes user input as prompts. Changes that add AI/LLM features. |
| **LLM02: Sensitive Disclosure** | New endpoints that might expose PII, secrets, or internal data. Changes to data export features. |
| **LLM03: Supply Chain** | New dependencies, package updates, Docker image changes. |
| **LLM04: Data Poisoning** | Changes to training data pipelines, data processing that could be influenced by attackers. |
| **LLM05: Excessive Agency** | New tool use or API call capabilities given to AI agents. |
| **LLM06: System Prompt Leakage** | Changes to prompts or instructions that might be exposed to users. |
| **LLM07: Vector/Embedding Weaknesses** | Changes to retrieval systems that could be manipulated. |
| **LLM08: Misinformation** | Changes to content generation that could produce false outputs. |
| **LLM09: Model Theft** | Changes to model serving that could allow weight extraction. |
| **LLM10: Unbounded Consumption** | New features that might cause excessive resource usage. |

### CVSS-Style Severity Scoring

```markdown
When assessing a finding in a diff, score it:

Severity = Impact × Likelihood × Exploitability

Impact: How bad is it if exploited?
  - Critical (4): Full system compromise, data breach, RCE
  - High (3): Significant data exposure, auth bypass
  - Medium (2): Limited data exposure, denial of service
  - Low (1): Minimal impact, informational

Likelihood: How likely is it to be exploited?
  - High (3): Trivial to exploit, no special conditions needed
  - Medium (2): Requires specific conditions or auth
  - Low (1): Very difficult to exploit, requires unlikely scenario

Exploitability: How easy is it to exploit?
  - High (3): Public tools, no skill needed
  - Medium (2): Requires some skill or special tools
  - Low (1): Requires deep expertise, custom exploit

Final Score = Impact × Likelihood × Exploitability

  27-36: CRITICAL — block merge
  18-26: HIGH — require security sign-off
  9-17: MEDIUM — address in follow-up PR
  1-8:  LOW — track and address later
```

### Review Checklist for Any Diff

```
Before approving a PR, verify:

SECURITY
[ ] No new SQL injection vectors (parameterized queries only)
[ ] No new XSS vectors (output encoding, CSP)
[ ] No weakened authentication or authorization
[ ] No new exposed endpoints without auth
[ ] No sensitive data in logs or error messages
[ ] New dependencies audited and approved
[ ] File uploads validated (type, size, content)
[ ] No hardcoded secrets or credentials

SUPPLY CHAIN
[ ] New packages verified (npm audit, safety check)
[ ] Docker images pinned to specific version
[ ] No :latest tags in production configs
[ ] Build scripts reviewed (no unexpected network calls)

QUALITY
[ ] Tests added for new functionality
[ ] Security-relevant tests cover edge cases
[ ] Error paths tested
[ ] No empty exception handlers (except: pass)

OPS
[ ] No new rate limiting removed
[ ] No new environment variables without defaults
[ ] No changes to infrastructure without security review
```

---

## Anti-Patterns

- **Rubber-stamping PRs** — "LGTM" without reading the diff is not a review. At minimum, read the files changed and understand what they do.

- **"Small change = safe"** — A one-line change can introduce a critical vulnerability. The size of the diff has no correlation with the security impact.

- **Ignoring transitive dependencies** — You may not add a dependency directly, but a dependency you already use might add a malicious one. Keep your dependencies updated.

- **Not checking test coverage for security changes** — A security-relevant change without tests means you cannot verify it continues to work after future changes.

- **Assuming the author reviewed for security** — Even senior engineers miss security issues. The reviewer's job is to catch what the author missed.

- **Approving based on trust in the author** — In open source, you review the code, not the author. In a company, the reviewer's job is to protect the system.

---

## Quick Reference

| Change Type | Risk | Action |
|------------|------|--------|
| New dependency | HIGH | Audit with npm audit / safety / docker scout |
| Auth change | CRITICAL | Two-person review, explicit sign-off |
| File upload | HIGH | Validate MIME, size, content, store outside web root |
| SQL query | HIGH | Verify parameterized only |
| New public endpoint | HIGH | Verify auth, rate limit, input validation |
| Config/env change | MEDIUM | Verify no secrets leaked |
| Version bump | LOW | Check changelog for security fixes |

### Git Diff Review Command

```bash
# Review a diff between branches
git diff main...feature-branch

# Review only changed files (summary)
git diff --stat main...feature-branch

# Review a specific commit
git show abc123

# Review files changed by a PR (GitHub CLI)
gh pr diff 123

# Search diff for dangerous patterns
git diff main...feature-branch | grep -E "passwd|secret|token|\.env|password"

# Check for removed security controls
git diff main...feature-branch | grep -E "auth|require|valid|check"
```

---

## Trail of Bits Methodology (`references/`)

The `references/` directory contains the full Trail of Bits differential review methodology:

| File | Purpose |
|------|---------|
| `methodology.md` | 6-phase workflow: Intake → Changed Code Analysis → Test Coverage → Blast Radius → Deep Context → Adversarial |
| `adversarial.md` | Phase 5 adversarial vulnerability analysis — attacker modeling, attack vector identification, exploitability rating, full exploit scenario construction |
| `patterns.md` | Common vulnerability patterns: security regressions, double decrease bugs, missing validation, underflow/overflow, reentrancy, access control bypass, race conditions, timestamp manipulation, unchecked returns, denial of service |
| `reporting.md` | Phase 6 report generation — 9-section report structure (Executive Summary, What Changed, Critical Findings, Test Coverage, Blast Radius, Historical Context, Recommendations, Methodology, Appendices) |

**Attribution:** This methodology is from [trailofbits/skills](https://github.com/trailofbits/skills) (MIT licensed). The agents/openai.yaml and assets/trail-of-bits-mark.svg are also from this source.

### Quick Detection Commands (from patterns.md)

```bash
# Find removed security checks:
git diff <range> | grep "^-" | grep -E "require|assert|revert"

# Find new external calls:
git diff <range> | grep "^+" | grep -E "\.call|\.delegatecall|\.staticcall"

# Find changed access modifiers:
git diff <range> | grep -E "onlyOwner|onlyAdmin|internal|private|public|external"

# Find arithmetic changes:
git diff <range> | grep -E "\+|\-|\*|/"
```

### Vulnerability Report Template (from adversarial.md)

```markdown
## [SEVERITY] Vulnerability Title

**Attacker Model:**
- WHO: [Specific attacker type]
- ACCESS: [Exact privileges]
- INTERFACE: [Specific entry point]

**Attack Vector:**
[Step-by-step exploit through accessible interfaces]

**Exploitability:** EASY/MEDIUM/HARD
**Justification:** [Why this rating]

**Concrete Impact:**
[Specific, measurable harm - not theoretical]

**Proof of Concept:**
```code
// Exact code to reproduce
```

**Root Cause:**
[Reference specific code change at file.sol:L123]

**Blast Radius:** [N callers affected]
**Baseline Violation:** [Which invariant/pattern broken]
```
