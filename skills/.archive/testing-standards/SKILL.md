---
name: testing-standards
description: Test writing standards, naming conventions, and coverage guidance
tags: [testing, quality, automation, best-practices]
tags: [testing, unit-test, tdd, quality, coverage, pytest, jest]
---

## When to Use

- Writing unit tests following AAA (Arrange-Act-Assert) pattern
- Setting up test naming conventions and file organization
- Determining what to test and at what granularity
- Measuring and enforcing code coverage standards
- Writing integration or end-to-end test specifications

## Do Not Use

- CI/CD pipeline configuration (use ci-cd-patterns)
- Code review checklists (use code-review)
- Framework-specific testing tools (use the framework's own patterns)
- Performance benchmarking or load testing
- Manual QA process documentation

# Testing Standards

## Test Structure (AAA Pattern)
```
Arrange — set up test data and dependencies
Act     — call the function/method being tested
Assert  — verify the expected outcome
```

## Naming Convention
`describe("ComponentName", () => {`
`  it("should [expected behavior] when [condition]", () => {`

## What to Test
- Happy path: normal expected input/output
- Edge cases: empty, null, zero, maximum values
- Error cases: invalid input, network failure, missing data
- State changes: before/after mutations

## What NOT to Test
- Implementation details (test behavior, not code)
- Third-party library internals
- Trivial getters/setters

## Coverage Targets
- Business logic: 90%+
- Utility functions: 80%+
- UI components: 60%+ (focus on interactions)
- Don't chase 100% — test what matters

## Test File Location
- Co-located: `src/auth/auth.test.ts` next to `src/auth/auth.ts`
- Or centralized: `tests/auth/auth.test.ts`
- Pick one convention per project and stick to it

## Running Tests
```bash
npm test          # JavaScript/TypeScript
pytest          # Python
go test ./...    # Go
cargo test       # Rust
```## Resources (awesome-python)

### Core Testing
| Library | Purpose |
|---------|---------|
| **pytest** | Default Python testing - fixtures, plugins, parametrize, autouse |
| **tox** | Matrix testing across Python versions - isolated venvs per env |
| **hypothesis** | Property-based testing - generate edge cases, shrink failures |
| **vcr.py** | Record/replay HTTP interactions - deterministic API tests |
| **mimesis** | Fake data generator for tests - locale-aware, type-hinted |
| **faker** | Popular fake data - names, addresses, emails, lorem ipsum |
| **factory-boy** | Declarative test fixtures - Django/SQLAlchemy integration |
| **model-bakery** | Django model fixtures - smart defaults, relationships auto-filled |

### Web Testing
| Library | Purpose |
|---------|---------|
| **playwright-python** | Modern browser automation - multi-tab, network mocking, mobile emulation |
| **selenium** | Classic browser testing - WebDriver, grid, multi-browser |
| **splinter** | Abstraction over browser drivers - simpler API than raw Selenium |

### Mocking
| Library | Purpose |
|---------|---------|
| **unittest.mock** | Built-in mocking - patch, Mock, MagicMock, PropertyMock |
| **pytest-mock** | pytest fixture for unittest.mock - cleaner teardown |
| **responses** | Mock HTTP requests library - intercept requests calls |
| **requests-mock** | Mock HTTP via requests library - URL matching, response templates |

### Coverage
| Library | Purpose |
|---------|---------|
| **pytest-cov** | pytest plugin for coverage.py - report per test file |
| **coverage.py** | Statement coverage - branch, line, HTML/XML reports |

### Fuzzing / Property-Based
| Library | Purpose |
|---------|---------|
| **hypothesis** | Property-based fuzzing - stateful testing, assume(), target() |
| **schemathesis** | API fuzzing from OpenAPI/Swagger - finds crashes and spec violations |
| **boofuzz** | Network protocol fuzzing - TCP/UDP, modbus, custom protocols |
| **crosshair** | Symbolic test generation - finds bugs by exploring all execution paths |

### Smoke Test Structure
`python
def test_imports():
    \"\"\"All modules import cleanly\"\"\"
    import myapp.core       # noqa: F401
    import myapp.api        # noqa: F401
    import myapp.models     # noqa: F401

def test_app_starts():
    \"\"\"App boots without crash\"\"\"
    from myapp import create_app
    app = create_app()
    assert app is not None

def test_db_connect():
    \"\"\"Database is reachable\"\"\"
    import psycopg2
    conn = psycopg2.connect(dsn="postgresql://localhost/test")
    assert conn.status == psycopg2.extensions.STATUS_READY
    conn.close()
`

## See Also
- 'python-patterns' - pytest integration, async test patterns
- 'data-analysis' - pandera schema testing
- 'cs-fundamentals' - hypothesis properties for CS algorithms
- 'database-patterns' - test fixtures for database state
