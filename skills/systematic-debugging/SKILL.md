---
name: systematic-debugging
description: "Systematic debugging methodology — root cause investigation, hypothesis-driven exploration, eliminating causes one by one. Use when encountering any bug, test failure, or unexpected behavior. Triggers: bug, error, broken, not working, debug, root cause, hypothesis, repro, trace, stack trace."
---

# Systematic Debugging

## When to use this

Load this skill whenever you encounter any bug, test failure, or unexpected behavior. This is the default skill for all bug investigation. It prevents the most common debugging mistake: fixing symptoms instead of causes.

---

## Core Principles

1. **Reproduce first** — Before you change anything, confirm you can reliably reproduce the bug. If you cannot reproduce it, you cannot verify the fix.

2. **Hypothesize before touching** — Make one or more educated guesses about the root cause before you start changing code. This prevents random fixes and wasted effort.

3. **Change one variable at a time** — If you change two things at once and the bug goes away, you do not know which change fixed it. Isolated changes are verifiable changes.

4. **The top of the stack trace is rarely the root cause** — The place where an error is thrown is often far from where the bug was introduced. Read the full trace.

5. **Eliminate causes one by one** — Start with the most likely cause. If that is not it, move to the next. Do not change multiple things in parallel.

6. **Document your investigation** — Keep notes on what you tried, what you found, and what you ruled out. This prevents re-investigating the same path.

7. **The fix should be verified and regression-tested** — After fixing, confirm the bug is gone and that the fix does not break anything else.

---

## Patterns

### The Debug Loop

```
REPRODUCE → HYPOTHESIZE → ISOLATE → FIX → VERIFY → REGRESSION TEST
    ↑___________|
    (if bug is not fixed, refine hypothesis and loop)
```

### Reproduce: Get a Minimal Reproduction

```python
"""
Before debugging, isolate the bug into a minimal reproduction case.
A minimal reproduction:
1. Has the fewest possible lines of code
2. Shows the bug in under 30 seconds
3. Can be run by another engineer without setup
"""

# WRONG: "It fails in the full test suite but not in isolation"
# This means the test environment has different state

# RIGHT: Minimal reproduction
import pytest

def test_fetch_user_with_invalid_id_returns_none():
    """Minimal reproduction of the bug."""
    # Setup: only what is needed to trigger the bug
    db = InMemoryDatabase()
    db.seed(users=[{"id": 1, "email": "a@b.com"}])

    # Action: the one call that triggers the bug
    result = fetch_user(user_id=999)  # Non-existent ID

    # Assertion: what you expect vs what happens
    assert result is None  # Bug: raises UserNotFoundError instead

# Run it:
# pytest test_repro.py -v
# If this passes (no error), the bug is NOT reproduced.
# If this fails with UserNotFoundError, bug is reproduced.
```

### Hypothesis-Driven Investigation

```python
"""
When you encounter a bug, write down your hypothesis BEFORE touching code.
This is the most effective way to avoid random debugging.
"""

# Template for bug investigation:
bug_report = """
Bug: Login fails for users with apostrophes in email

HYPOTHESIS 1 (most likely): SQL injection prevention is too aggressive
  - Evidence: The login form uses parameterized queries
  - Test: Does the login work for 'user@example.com'? (yes)
  - Test: Does it work for "user'o'reilly@example.com"? (fails)
  - If yes: the issue is in the email validation/escaping

HYPOTHESIS 2 (less likely): Email normalization removes apostrophe incorrectly
  - Test: Log the email as it arrives at the login endpoint
  - Check: Does the apostrophe survive normalization?

HYPOTHESIS 3 (rare): Database column collation ignores apostrophes
  - Test: Direct SQL query with the same email

ACTION: Start with HYPOTHESIS 1 — check the email validation regex.
"""

# When you test HYPOTHESIS 1:
# - Find the email validation code
# - Run the email through the same validation function
# - If it fails, you've found the root cause
# - If it passes, move to HYPOTHESIS 2
```

### Binary Search (Bisection) Through Changes

```bash
# When did this bug appear? Use git bisect to find the bad commit.
git bisect start
git bisect bad                  # Current commit is bad
git bisect good v1.0.0          # Last known good version

# Git will checkout a commit in between.
# Run your test: if it passes, mark good; if it fails, mark bad.
# Repeat until the bad commit is found.
git bisect good   # or: git bisect bad
git bisect reset # when done

# Result: git tells you the exact commit that introduced the bug
```

### Reading Stack Traces Effectively

```python
# Python stack trace example:
Traceback (most recent call last):
  File "app.py", line 42, in handle_request
    return process_order(order_data)
  File "order.py", line 87, in process_order
    order = validate_order(order_data)
  File "order.py", line 134, in validate_order
    raise ValidationError(f"Invalid product: {product_id}")

# How to read it:
# - Line 134: this is where the error is RAISED — not necessarily where the bug is
# - Line 87: validate_order() was called with bad data
# - Line 42: handle_request() passed bad data to validate_order
# - The ROOT CAUSE is: handle_request passed invalid product_id to validate_order
# - The FIX is in handle_request (line 42), not in validate_order

# Debugging technique: Add a breakpoint at the top of the stack
# and work your way down:
import pdb; pdb.set_trace()  # in app.py line 42
# Inspect: order_data — what does it contain?

# Then: (pdb) where  # shows full stack
# Then: (pdb) up    # go to validate_order
# Then: (pdb) step  # step through validate_order
```

### Isolating Variables

```python
# When the bug involves multiple variables, isolate each one:

def test_bug_integration():
    # WRONG: Change multiple things
    # config['timeout'] = 30
    # config['retries'] = 5
    # config['cache'] = False
    # if bug_fixed: # which change fixed it?

    # RIGHT: Change one at a time
    config = get_config()

    # Test 1: Timeout alone
    config['timeout'] = 30
    apply_config(config)
    result = run_test()
    print(f"After timeout=30: {result}")  # Still broken

    # Test 2: Retries alone
    config = get_config()  # Reset
    config['retries'] = 5
    apply_config(config)
    result = run_test()
    print(f"After retries=5: {result}")  # Still broken

    # Test 3: Cache alone
    config = get_config()  # Reset
    config['cache'] = False
    apply_config(config)
    result = run_test()
    print(f"After cache=False: {result}")  # BUG FIXED!
    # Root cause: cache was returning stale data
```

### Divide and Conquer with Logs

```python
# Add targeted logging to narrow down where the bug occurs:

def process_order(order):
    logger.info(f"process_order: START order_id={order['id']}")
    order = validate_order(order)
    logger.info(f"process_order: AFTER VALIDATE order_id={order['id']}")
    order = enrich_order(order)
    logger.info(f"process_order: AFTER ENRICH order_id={order['id']}")
    order = save_order(order)
    logger.info(f"process_order: AFTER SAVE order_id={order['id']}")
    return order

# If you see START but not AFTER VALIDATE:
# The bug is in validate_order()

# If you see AFTER VALIDATE but not AFTER SAVE:
# The bug is in enrich_order() or save_order()
```

### The "It Works on My Machine" Protocol

```bash
# When someone says "it works on my machine":
# 1. Confirm the environment is actually different
echo "=== Environment ==="
python --version
node --version
git log --oneline -1

# 2. Check dependency versions
pip freeze | grep -E "flask|requests"
npm list --depth=0

# 3. Check for environment variables
env | grep -E "DEBUG|ENV|PORT|DATABASE"

# 4. Check git state — uncommitted changes?
git status
git diff

# 5. Compare with CI environment
#    The CI environment is the source of truth.
#    If it fails in CI and passes locally, your local is wrong.
```

---

## Anti-Patterns

- **Random fixes without hypothesis** — Changing things at random until the bug goes away is not debugging — it is hoping. You will introduce new bugs and not know what fixed the original one.

- **"It works on my machine"** — The CI environment is the source of truth. If it fails in CI, your local environment is misleading you. Debug in the CI environment.

- **Not reading the full stack trace** — The top of the stack trace is where the error was thrown, not where the bug was introduced. Always read the full trace from bottom to top.

- **Changing multiple variables simultaneously** — If the bug disappears after you changed three things, you do not know which one actually fixed it. Isolate changes.

- **Fixing symptoms instead of causes** — If your fix is in the error handler rather than the code that generates the bad data, you have not fixed the bug — you have hidden it.

- **Not verifying the fix** — A bug is not fixed until you have a test that fails before the fix and passes after. Without a test, the bug will come back.

- **Not documenting the investigation** — Future engineers (often future you) will need to understand what was tried and what was ruled out. Keep notes.

---

## Quick Reference

| Step | Action | Tool |
|------|--------|------|
| Reproduce | Create minimal test case | pytest, curl, browser |
| Hypothesize | Write down guesses before touching code | pen and paper |
| Isolate | Change one variable at a time | git stash, feature flags |
| Locate | Read stack trace, add logs | pdb, logger |
| Verify | Run the reproduction test | pytest |
| Regression | Run full test suite | pytest, CI |
| Document | Record hypothesis, tests, and findings | comments, PR description |

### Minimal Reproduction Checklist

```
A minimal reproduction must:
1. Be runnable without any application setup (just: python test.py)
2. Have no external dependencies (no DB, no network)
3. Fail reliably in under 5 seconds
4. Not require any special environment variables
5. Be self-contained in a single file

If you cannot create a minimal reproduction, the bug is likely:
- An environmental difference (check env vars, versions)
- A race condition (try running 10 times with --count=10)
- A data-dependent issue (check what data is in the DB)
```

---

## Deep Patterns (`references/`)

The `references/` directory contains advanced debugging patterns from [obra/superpowers](https://github.com/obra/superpowers):

| File | Purpose |
|------|---------|
| `root-cause-tracing.md` | Trace backward through call chain to find original trigger — never fix just where error appears, fix at source. Includes stack trace instrumentation and `find-polluter.sh` usage. |
| `condition-based-waiting.md` | Wait for conditions, not guesses — eliminates flaky tests caused by arbitrary delays. Includes polling implementation and common mistakes. |
| `defense-in-depth.md` | Validate at every layer data passes through — entry point, business logic, environment guards, debug instrumentation. Makes bugs structurally impossible. |
| `test-pressure-*.md` | Test pressure scenarios for stress-testing edge cases |
| `test-academic.md` | Academic testing patterns and theory |

### Scripts (`scripts/`)

| File | Purpose |
|------|---------|
| `condition-based-waiting-example.ts` | TypeScript implementation of `waitFor`, `waitForEvent`, `waitForEventCount`, `waitForEventMatch` from real debugging sessions |
| `find-polluter.sh` | Bisection script to find which test pollutes shared state — runs tests one-by-one, stops at first polluter |

### Root Cause Tracing Principle

**Never fix just where the error appears.** Trace backward through the call chain:

```
Symptom appears deep in stack
  → Find immediate cause
  → Ask: What called this?
  → Keep tracing up
  → Find original trigger
  → Fix at source
  → Add validation at each layer (defense-in-depth)
```

**4-Layer Defense-in-Depth:**
1. **Entry validation** — reject obviously invalid input at API boundary
2. **Business logic validation** — ensure data makes sense for the operation
3. **Environment guards** — prevent dangerous operations in specific contexts (e.g., refuse git init outside tmpdir during tests)
4. **Debug instrumentation** — capture context for forensics when other layers fail

### Condition-Based Waiting Principle

**Wait for the actual condition, not a guess about timing:**

```typescript
// ❌ WRONG: Arbitrary delay
await new Promise(r => setTimeout(r, 50));
const result = getResult();

// ✅ RIGHT: Wait for condition
await waitFor(() => getResult() !== undefined);
const result = getResult();
```

**Requirements if arbitrary timeout IS correct:**
1. First wait for the triggering condition
2. Based on known timing (not guessing)
3. Comment explaining WHY the delay is necessary
