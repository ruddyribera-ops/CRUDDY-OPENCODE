---
name: awesome-differential-review
description: "Security-focused differential code review — comparing changes against baseline, identifying security regressions, supply-chain risks, and OWASP ASI 2026 threats. Use when reviewing PRs, validating changes, or auditing blast radius. Triggers: differential review, security regression, supply chain, CVE, OWASP, blast radius, code diff, blast radius assessment."
triggers:
  - differential review
  - PR review
  - security regression
  - supply chain
  - CVE
  - OWASP
  - blast radius
  - code diff
  - change review
applies_to:
  - code-reviewer
  - cybersecurity
  - main-coordinator
---

# Differential Code Review

## When to use this

Load this skill when:

- Reviewing a PR or code change for security implications
- Auditing a diff for supply-chain risks (new dependencies, lockfile changes)
- Assessing blast radius of a change before merge
- Looking for regressions introduced by recent changes
- Validating that a security fix actually closes the vulnerability

Do NOT use this skill when:

- Reviewing a fresh codebase from scratch (use code-analyzer instead)
- Just looking for style/lint issues (use code-reviewer)
- Threat-modeling from architecture diagrams (use architecture-advisor)

---

## Method

### Step 1: Establish the baseline

Before reviewing the diff, understand the state BEFORE the change:

```bash
git log --oneline -10              # recent history
git show main:path/to/file         # pre-change version
```

If the change is from a PR, the baseline is `main` (or the merge target).

### Step 2: Classify the change type

Categorize each hunk:

| Type | Examples | Risk profile |
|------|----------|--------------|
| **Dependency** | `package.json`, `requirements.txt`, lockfile changes | Supply chain — check CVE databases |
| **Auth/Crypto** | New auth flow, password handling, JWT validation | OWASP A07 (auth failures) |
| **Input handling** | User input → DB query, shell, file path | OWASP A03 (injection) |
| **Configuration** | env vars, secrets, infra config | Secret leakage risk |
| **Data flow** | API contract changes, schema migrations | Backward compat |
| **Logic** | Business logic changes | Correctness |

### Step 3: Apply OWASP ASI 2026 lens

For each change, ask:

- **Agent Goal Hijack**: Could this code path be subverted to change agent behavior?
- **Tool Misuse**: Could this be tricked into calling wrong tools?
- **Identity Theft**: Could credentials be exposed or impersonated?
- **RCE via Code**: Is there any code that runs other code unsafely?
- **Sanitization Bypass**: Are inputs validated? Bypassable?

### Step 4: Check supply chain

For dependency changes:

```bash
# Get new dep version
git diff main..HEAD -- package.json | grep '"version"'
# Check CVE database (npm audit, pip-audit, etc.)
npm audit --json
pip-audit --strict
```

For lockfile changes (yarn.lock, package-lock.json), every transitive dep change is a potential supply-chain risk.

### Step 5: Blast radius assessment

If this change ships and breaks, what's the worst case?

- Single user affected? → Low priority
- All users? → Critical, requires escalation
- Data loss possible? → Block merge
- Security breach possible? → Block merge + escalate

---

## Output format

```markdown
## Differential Review — [PR/Change ID]

### Change Summary
- Type: [dependency | auth | input | config | data | logic]
- Files: N
- Lines: +X / -Y

### Security Findings
- [SEVERITY] [title]: [details] → [fix]

### Supply Chain
- New deps: [list with version, CVE status]
- Lockfile changes: [transitive count]

### Blast Radius
- Worst case: [scenario]
- Affected users: [scope]
- Recommendation: [ship | block | needs review]

### Cross-References
- Related issues: [list]
- Related ADRs: [list]
```

---

## Cross-references

- `agents/code-reviewer.md` — general code review (this skill is more focused on security)
- `agents/cybersecurity.md` — for security-specific questions
- `rules/secure-coding.md` — secure coding practices