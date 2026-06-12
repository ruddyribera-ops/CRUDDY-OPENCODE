# Support Agent — Test Prompts

## Positive (should route to support, handled by support)

### Prompt 1 — Bug report / deployment issue
```
I tried to deploy my app and got a 500 error. The logs say 'connection refused' on port 5432. What should I do?
```
**Expected behavior:** Support reads full message, categorizes as bug report, checks knowledge base for Railway/postgres connection issues, drafts response with: (1) acknowledge the 500 error + connection refused, (2) explain likely cause (postgres not running / wrong host), (3) single clear next step (check DATABASE_URL env var, verify postgres is up). If unsure, escalate to @bug-fixer with full context.

### Prompt 2 — Question / how-do-I
```
How do I reset my password? I can't find the option in the settings.
```
**Expected behavior:** Support reads full message, categorizes as question, checks knowledge base for password reset flow, drafts response with: (1) acknowledge they can't find it, (2) explain where to find it (settings > security > change password), (3) single clear next step.

### Prompt 3 — Complaint
```
This is unacceptable. I've been waiting 3 days for my API key and nobody has responded to my ticket.
```
**Expected behavior:** Support reads full message, categorizes as complaint, leads with empathy ("I hear you — 3 days with no response is not acceptable"), acknowledges the frustration, escalates to @account-manager with full context (API key request, 3-day wait, ticket #).

### Prompt 4 — Escalation request
```
I need to speak to a human. This bot isn't helping me.
```
**Expected behavior:** Support reads full message, categorizes as escalation request + complaint, does not argue or defend the bot, escalates to @account-manager with full context and best-guess summary of what the user needs.

---

## Negative (should NOT be handled by support — route elsewhere)

### Prompt 5 — Code fix request (→ bug-fixer)
```
Refactor my authentication module to use JWT instead of sessions. The current implementation uses cookie-based sessions.
```
**Expected behavior:** Support does NOT act. Routes to @bug-fixer or @code-builder. This is a code implementation request, not a support question.

### Prompt 6 — New feature request (→ project-manager)
```
It would be great if the app could send SMS notifications when a build fails. Can you add that?
```
**Expected behavior:** Support does NOT act. Routes to @project-manager. This is a feature request, not a support question.

### Prompt 7 — Internal agent (→ appropriate specialist, not support)
```
@support — the client is asking about the roadmap for Q3. Can you give them an update?
```
**Expected behavior:** Support does NOT act as first responder. Routes to @project-manager or @account-manager. Internal agent-to-agent requests don't go through support triage.

### Prompt 8 — Security audit (→ cybersecurity)
```
Can you audit the codebase for SQL injection vulnerabilities?
```
**Expected behavior:** Support does NOT act. Routes to @cybersecurity. This is a security review task, not a support question.
