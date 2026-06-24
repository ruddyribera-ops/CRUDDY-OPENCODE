---
name: investigate
description: Deep investigation methodology — gstack pattern, full-stack evidence gathering, root cause through systematic exploration. Use when standard debugging is not enough; for complex multi-system bugs. Triggers: investigate, deep dive, gstack, multi-system bug, complex issue, full-stack investigation.
---

# Investigate

## When to use this

Load this skill when standard debugging has failed to identify the root cause, when the bug spans multiple systems (frontend + backend + database + network), or when you need a structured methodology for complex multi-day investigations. This is the skill for deep-dive debugging that goes beyond the stack trace.

---

## The gstack Pattern

**gstack** stands for **Gather → Stack → Track → Ack → Narrate → Complete**

This is a structured methodology for complex investigations where the bug is not immediately apparent from logs or stack traces.

```
GATHER     → Collect all evidence before forming a theory
STACK      → Build the call/data flow chain
TRACK      → Follow the problem through each hop
ACK        → Confirm each hop is working correctly
NARRATE    → Document findings as you go
COMPLETE   → Verify the full path works end-to-end
```

---

## Core Principles

1. **Evidence first, theory second** — Collect all available data before forming a hypothesis. Guessing before gathering leads to confirmation bias.

2. **Distinguish proximate cause from root cause** — The system that threw the error is often not the system that caused the error. Keep asking "why" until you reach the actual cause.

3. **Multi-system tracing** — Complex bugs span multiple systems. Trace the request from the browser/client through every hop to the database and back.

4. **Communicate during investigation** — For complex bugs, send periodic status updates to stakeholders. "Still investigating" is acceptable; silence is not.

5. **Document everything in real time** — Notes taken during investigation are gold. Notes written after the fact are incomplete and biased by what you now know.

6. **Do not assume the happy path is correct** — Every assumption that "this must be working" must be verified. The obvious system is often the culprit.

7. **Use the right tool for each layer** — Network traces for network issues, database logs for query issues, application traces for logic bugs. Each system has its own diagnostic tooling.

---

## Patterns

### gstack: Step-by-Step

```
GATHER
  - What is the symptom? (not the same as the bug)
  - What error messages exist? (exact text)
  - What does the stack trace show?
  - What do the logs show around the error time?
  - What changed recently? (deploy, config, data)
  - Who does it affect? (all users, some users, specific data)
  - When did it start? (timestamp, correlate with events)

STACK
  - Trace the full call chain: client → load balancer → API → DB
  - Identify all systems involved
  - Identify all data dependencies
  - Map the architecture

TRACK
  - Follow the request through each system
  - Check health at each hop
  - Verify data at each transformation point

ACK
  - At each hop: confirm it is working correctly
  - Mark each system as "verified" or "suspect"
  - When a system is suspect, dig deeper

NARRATE
  - Write up findings in real time
  - Include: what you checked, what you found, what you ruled out
  - Include: timestamps, error messages, key data points

COMPLETE
  - Once root cause found, reproduce it
  - Fix it
  - Verify fix with a test
  - Confirm no regression
```

### Evidence Gathering Checklist

```python
# Template for complex bug investigation:

investigation_notes = """
=== INVESTIGATION: [Bug title] ===
Date: [timestamp]
Priority: [P1/P2/P3]
Affected: [what is broken]

=== EVIDENCE GATHERED ===

Symptom:
  [What users see — exact error message or behavior]

Error logs (application):
  [Paste relevant log lines with timestamps]

Stack trace:
  [Full stack trace, if available]

Database logs:
  [Query logs, slow query log, connection errors]

Network:
  [Latency, timeouts, connection resets]

Environment:
  - Git commit: [git rev-parse HEAD]
  - Deploy time: [when was this deployed]
  - Config: [relevant env vars / config changes]
  - Data: [any bulk data operations recently]

=== RECENT CHANGES ===
  [List all changes in the last 24-48 hours]

=== STACK TRACE (call chain) ===
  [Map each step: client → ... → database]

=== TRACKING LOG ===
  [Track each hop as you verify it]

  Hop 1: CDN
    Status: VERIFIED / SUSPECT / UNKNOWN
    Evidence: [what you checked and what you found]

  Hop 2: Load Balancer
    Status: VERIFIED / SUSPECT / UNKNOWN
    Evidence: [what you checked and what you found]

  Hop 3: API Server
    Status: VERIFIED / SUSPECT / UNKNOWN
    Evidence: [what you checked and what you found]

  Hop 4: Database
    Status: VERIFIED / SUSPECT / UNKNOWN
    Evidence: [what you checked and what you found]

=== ROOT CAUSE ===
  [The actual bug — not the symptom]

=== FIX ===
  [What you changed to fix it]

=== VERIFICATION ===
  [How you confirmed the fix works]

=== REGRESSION TESTING ===
  [What you ran to confirm no new bugs introduced]
"""
```

### Multi-System Tracing Example

```bash
# Step 1: Check the client-side network trace
# In browser DevTools, check:
# - What request was made?
# - What was the response status code?
# - What was the response body?
# - What was the timing?

# Step 2: Check the load balancer / gateway logs
# AWS ALB logs show: timestamp, client IP, target, latency, status codes
# Filter by the request ID from Step 1

# Step 3: Check the API server logs
# Search for the request ID across all API logs
grep "req_id=abc123" /var/log/api/*.log

# Step 4: Check the database
# Was the query executed? What was the query plan?
# PostgreSQL: SELECT * FROM pg_stat_activity WHERE state = 'active';
# SQLite: .indices, EXPLAIN QUERY PLAN

# Step 5: Reconstruct the full timeline
# Combine all logs with timestamps to create a timeline:
# 12:00:00.001  CLIENT  → GET /api/users/123
# 12:00:00.050  ALB     → forwarded to api-server-1
# 12:00:00.100  API     → Query: SELECT * FROM users WHERE id = 123
# 12:00:00.600  API     → Query took 500ms (slow — missing index?)
# 12:00:00.601  API     → Responded 200
# 12:00:00.650  ALB     → Response to client
```

### Slow Query Investigation

```sql
-- PostgreSQL: Find slow queries
SELECT
    query,
    calls,
    mean_time,
    total_time,
    rows
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;

-- Find queries with high total time (cumulative impact)
SELECT
    query,
    calls,
    mean_time,
    total_time,
    rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;

-- Check for missing indexes on a specific table
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename = 'orders'
ORDER BY idx_scan ASC;

-- Run EXPLAIN ANALYZE on the slow query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.*, u.name
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.created_at > '2024-01-01'
ORDER BY o.created_at DESC
LIMIT 100;
```

### Memory / Resource Investigation

```python
# Python memory investigation
import tracemalloc
import gc

# Start tracing
tracemalloc.start()

# Run the problematic code
result = run_slow_operation()

# Get memory snapshot
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

print("[ Top 10 memory consumers ]")
for stat in top_stats[:10]:
    print(stat)

# Find memory leaks
# Run the operation multiple times, check if memory grows
import psutil
import os

process = psutil.Process(os.getpid())
initial_mem = process.memory_info().rss

for i in range(10):
    run_operation()

gc.collect()  # Force garbage collection
final_mem = process.memory_info().rss

if final_mem > initial_mem * 1.5:
    print(f"MEMORY LEAK: Initial={initial_mem/1024/1024:.1f}MB, Final={final_mem/1024/1024:.1f}MB")

# JavaScript/Node.js memory investigation
# node --inspect app.js
# Then use Chrome DevTools memory profiler
```

### Root Cause vs Proximate Cause

```python
"""
Example: API returns 500 error

PROXIMATE CAUSE: The API throws an unhandled exception
ROOT CAUSE: The database connection pool was exhausted because
            a long-running query held connections open, and the
            new query could not get a connection.

PROXIMATE CAUSE: (API layer) Unhandled exception
ROOT CAUSE: (Database layer) Connection pool exhaustion
DEEPER CAUSE: (Query layer) Missing index on orders.user_id caused
              a sequential scan that took 30 seconds instead of 10ms

FIX: Add index on orders.user_id
"""
```

### Communication Template for Complex Bugs

```markdown
Subject: [INVESTIGATING] Bug: Users cannot login (P1)

Status: INVESTIGATING — root cause not yet identified
Affected: All users attempting login since 14:00 UTC
Impact: 100% of login attempts failing

What I know:
- Login form returns "Internal Server Error" (500)
- API logs show: "Connection refused" to database
- Database server is running and accepting connections from other services

What I've checked:
- [x] Database server process — running
- [x] Database disk space — 40% used
- [x] Database connection limit — not hit
- [x] Network connectivity from API to DB — failing (timeout)

Suspect: Network issue between API server and database
Next step: Check firewall rules and security groups

ETA: 30 minutes to root cause
```

---

## Anti-Patterns

- **Jumping to conclusions before gathering evidence** — Confirmation bias is real. If you decide the root cause before investigating, you will only look for evidence that supports your theory.

- **Relying on a single source of evidence** — A stack trace from the application log does not tell you what the database saw. The bug spans all systems. Gather from all of them.

- **Assuming the obvious system is working correctly** — The system that "should be fine" is often the culprit. Verify everything, assume nothing.

- **Not documenting during investigation** — Writing findings after the fact is biased by what you now know. Document in real time.

- **Silence during long investigations** — Stakeholders need to know you are working on it. Send updates even if you have not found the root cause yet.

- **Stopping at the first plausible cause** — The first cause you find is often a symptom. Keep asking "why" until you reach the actual root cause.

---

## Quick Reference

| Investigation Phase | Key Question | Tools |
|-------------------|--------------|-------|
| GATHER | What evidence exists? | Logs, traces, metrics, network |
| STACK | What systems are involved? | Architecture diagram, dependency graph |
| TRACK | Is each hop working? | Health checks, ping, connectivity tests |
| ACK | Can I confirm this hop is healthy? | Request tracing, log correlation |
| NARRATE | What have I found and ruled out? | Investigation notes |
| COMPLETE | Is the full path fixed? | End-to-end test |

### Investigation Start Checklist

```
Before starting the deep investigation:
1. Confirm the bug is reproducible (if not, it may have already been fixed)
2. Define the scope: what is affected, what is not
3. Set a time budget (e.g., 2 hours) before escalating
4. Identify who else needs to be involved (DBA, SRE, network engineer)
5. Create the investigation notes document
```
