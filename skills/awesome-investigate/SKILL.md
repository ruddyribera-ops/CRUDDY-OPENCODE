---
name: awesome-investigate
description: "Deep investigation methodology — gstack pattern for full-stack evidence gathering and root cause through systematic exploration. Use when standard debugging isn't enough, for complex multi-system bugs. Triggers: investigate, deep dive, gstack, multi-system bug, complex issue, full-stack investigation."
triggers:
  - investigate
  - deep dive
  - gstack
  - multi-system bug
  - complex issue
  - full-stack investigation
  - root cause analysis
applies_to:
  - bug-fixer
  - expert-tester
  - observability-sre
---

# Deep Investigation — gstack Pattern

## When to use this

Load this skill when:

- A bug spans multiple systems (frontend + backend + DB + external API)
- Standard debugging (read code, run tests) hasn't found the root cause
- The issue is intermittent or hard to reproduce
- You need to gather evidence from multiple sources before forming a hypothesis
- A "simple" fix has failed 3+ times

Do NOT use this skill when:

- The bug is obvious from stack trace or error message
- The cause is in a single function or file
- You're doing exploratory development, not debugging

---

## gstack Method — 6 Phases

### Phase 1: Symptom Inventory

Before forming any hypothesis, catalog every observable:

- Error messages (full text, not paraphrased)
- Timestamps (when did it start? is it getting worse?)
- Affected users / requests (1%? 50%? 100%?)
- Reproduction steps (does it always happen? intermittent?)
- Environmental differences (dev vs prod? specific user agent?)

Write this DOWN. Don't skip.

### Phase 2: Boundary Mapping

Identify every system component the request touches:

```
Client → CDN → Load Balancer → API Gateway → Auth Service → App Server → DB
                                                              ↓
                                                        Cache Layer
                                                              ↓
                                                        External API
```

For each boundary, note what could go wrong (network, timeout, schema mismatch, auth failure, etc.).

### Phase 3: Evidence Gathering

Run actual probes at each boundary:

```bash
# Network
curl -v https://api.example/health
traceroute api.example

# Auth
curl -H "Authorization: Bearer $TOKEN" https://api.example/me

# App server
journalctl -u myapp --since "1 hour ago"
pm2 logs --lines 200

# DB
psql -c "SELECT * FROM sessions WHERE id = 'failing_id'"
```

Capture EXACT output, not summaries.

### Phase 4: Hypothesis Ranking

Based on evidence, list possible causes ordered by likelihood:

1. **Most likely**: [cause] — [evidence supporting]
2. Second: [cause] — [evidence]
3. Third: [cause] — [evidence]

Don't fall in love with your first hypothesis. The data decides.

### Phase 5: Targeted Experiments

Design minimal experiments to DISPROVE each hypothesis:

- "If hypothesis 1 is true, then X should be Y. Let's check X."
- "If hypothesis 2 is true, then Z should happen. Let's trigger Z."

One experiment per hypothesis. Don't change multiple variables at once.

### Phase 6: Root Cause + Fix

Once you've isolated the cause:

1. Document the chain: symptom → boundary → component → exact line
2. Write the minimal fix
3. Verify the fix doesn't introduce new issues
4. Add a regression test
5. Update docs/runbooks if the failure mode is repeatable

---

## Output format

```markdown
## Investigation — [Brief description]

### Symptom
[What users see, when, how often]

### Boundary Map
[ASCII diagram of components]

### Evidence
- [Boundary 1]: [observation]
- [Boundary 2]: [observation]

### Hypothesis Ranking
1. [Most likely cause] — [supporting evidence]
2. ...

### Experiment Results
- Hypothesis 1: [DISPROVEN | CONFIRMED | INCONCLUSIVE]
- Hypothesis 2: ...

### Root Cause
[Exact component + line]

### Fix
[Minimal change]

### Regression Test
[Test added to prevent recurrence]
```

---

## Cross-references

- `rules/systematic-debugging.md` — for simpler bugs
- `agents/expert-tester.md` — for test-based investigation
- `agents/observability-sre.md` — for production incidents