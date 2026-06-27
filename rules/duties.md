# Segregation of Duties — OpenCode Agent System

**Purpose:** Prevent conflicts of interest where the same agent could implement, review, and deploy code without oversight. Enforced by the main-coordinator at routing time.

---

## Role Definitions

| Role | Agents | Can Do | Cannot Do |
|------|--------|--------|-----------|
| **coordinator** | main-coordinator | Route tasks, classify, enforce rules, dispatch, log | Write code, debug, explain, implement |
| **executor** | code-builder, bug-fixer | Write, modify, fix code, run tests | Review or approve own work, make architectural decisions |
| **analyzer** | code-analyzer, code-explainer | Read, scan, analyze, explain, audit | Modify code, write files, execute destructive commands |
| **decider** | architecture-advisor | Recommend, evaluate tradeoffs, design, write ADRs | Implement code, modify existing codebase |
| **reporter** | standup-summary | Read git history, report status, identify issues | Modify code, make changes |
| **generator** | project-generator | Scaffold, generate plans, create new projects | Modify existing project code |
| **curator** | skill-manager | Create/update skills, manage memory, enrich config | Modify application code |

---

## Conflict Matrix

```
checks  = allowed
warns   = allowed but coordinator flags
rejects = blocked by coordinator
```

| | executor | analyzer | decider | reporter | coordinator | generator | curator |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **executor** | checks | checks | checks | checks | checks | checks | checks |
| **analyzer** | checks | checks | checks | checks | checks | checks | checks |
| **decider** | checks | checks | checks | checks | **warns** | **warns** | checks |
| **reporter** | checks | checks | checks | checks | checks | checks | checks |
| **coordinator** | checks | checks | **warns** | checks | checks | **warns** | checks |
| **generator** | checks | checks | **warns** | checks | **warns** | checks | checks |
| **curator** | checks | checks | checks | checks | checks | checks | checks |

### Conflict Explanations

| Conflict | Why |
|----------|-----|
| **decider → coordinator** | Architect advising coordinator on routing creates feedback loop |
| **decider → generator** | Architect shouldn't steer scaffold before requirements clear |
| **coordinator → decider** | Coordinator routing to architect creates bias toward over-engineering |
| **coordinator → generator** | Coordinator should not influence generation decisions |

---

## Enforcement Flow

```
Agent A attempts to delegate to Agent B
  → Coordinator checks duties.md
  → If checks: route normally
  → If warns: route but surface conflict to user
  → If rejects: block route, explain why, suggest alternative
```

**When duties conflict occurs:**
1. Coordinator explains the conflict in one line
2. Suggests the approved alternative
3. User can override ("proceed anyway") — exceptions are logged

---

## Self-Review Prohibition (Hard Rule)

**No executor may review its own work.**

- code-builder cannot verify its own code as "done"
- bug-fixer cannot declare its own fix as "verified"
- Use a separate agent for verification: analyzer reviews executor work

**Enforcement:**
- If code-builder reports "✅ done" with self-review → flag as unverified
- Require code-analyzer pass before declaring complete on critical paths

---

## Segregation of Duties by Task Type

| Task | Creates | Reviews | Decides |
|------|---------|---------|---------|
| **New feature** | code-builder | code-analyzer | architecture-advisor |
| **Bug fix** | bug-fixer | code-analyzer | (none needed) |
| **Refactor** | code-builder | code-analyzer | architecture-advisor |
| **Security patch** | bug-fixer | code-analyzer (security path) | architecture-advisor |
| **New project** | project-generator | architecture-advisor | (user decides) |
| **Production deploy** | (git push) | code-analyzer | architecture-advisor |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-05-19 | Created — Phase 1.2 of Harness Improvement POA |
