---
name: python-patterns
description: Modern Python 3.10+ patterns, type hints, FastAPI, Pydantic, and async best practices
tags: [python, backend, patterns, best-practices]
tags: [python, type-hints, fastapi, pydantic, async, python310, best-practices]
---

## When to Use

- Writing modern Python 3.10+ code with type hints and structural pattern matching
- Building FastAPI web applications with Pydantic v2 validation
- Implementing async/await patterns for concurrent I/O operations
- Designing Python packages and modules following PEP standards
- Writing clean, maintainable Python with proper typing and error handling

## Do Not Use

- Legacy Python 2.x or Python < 3.10 codebases
- GPU-accelerated computing or CUDA programming (use cs-fundamentals)
- Data analysis with pandas/numpy (use data-analysis for specialized patterns)
- Android development (use android-native-dev)
- iOS/macOS development (use ios-application-dev)

# Python Modern Patterns

## Type Hints (3.10+)
- Use built-in generics: `list[str]`, `dict[str, int]` (no `typing.List`/`typing.Dict`)
- Union with `|`: `int | None` instead of `Optional[int]`
- `type` alias for complex types: `type UserId = int`

## Dataclasses → Pydantic → FastAPI (Progression)
| Concern | Tool | Use Case |
|---------|------|----------|
| Data containers | `@dataclass` | Internal data, no validation needed |
| Validation + serialization | Pydantic `BaseModel` | API boundaries, forms, config |
| Web API framework | FastAPI | REST endpoints with OpenAPI |

## Core Patterns (with code)

→ See `references/code-examples.md` for complete code:

| Pattern | Key Points |
|---------|------------|
| Type Hints | Built-in generics, `|` union, `type` alias |
| Dataclasses | `frozen=True` for immutability, `field(default_factory=...)` for mutables |
| Pydantic Models | `Field(ge=0, le=150)`, `@field_validator`, `model_config` |
| FastAPI | Dependency injection via `Depends`, query validation via `Query`, async endpoints |
| Async/Await | `asyncio.gather` for parallel, `return_exceptions=True`, `asyncio.wait_for` for timeouts |
| Error Handling | Custom hierarchy (`AppError`), Result pattern for functional style |
| Decorators | `@retry` with exponential backoff |
| Context Managers | `@contextmanager`, `@asynccontextmanager` for resource management |
| Anti-Patterns | Global config, sync-in-async, unbounded list comps, `Optional` misuse |

## Pydantic v2 Migration (from v1)

| v1 | v2 |
|----|----|
| `@validator` | `@field_validator` (with `@classmethod`) |
| `class Config` | `model_config = {...}` dict |
| `.dict()` | `.model_dump()` |
| `.json()` | `.model_dump_json()` |
| `orm_mode = True` | `from_attributes = True` |
| `parse_obj()` | `model_validate()` |

→ Full migration example in `references/code-examples.md`

## Async Gotchas

- **Never `time.sleep()` in async** → use `await asyncio.sleep()`
- **Gather exceptions:** Always `return_exceptions=True` to let other tasks finish
- **Timeouts:** Always set `asyncio.wait_for(coro, timeout=5)` on external calls
- **Connection pools:** Reuse clients (`async with httpx.AsyncClient() as client`)

## Learned from PRIA (Streamlit)
- Import heavy libs in functions (not top level) — Streamlit re-runs entire script
- Use `st.session_state` for persistence (local vars reset on rerun)
- Call async with `asyncio.run()` in Streamlit
- Pydantic models for form data validation

## Ecosystem
→ See `references/ecosystem.md` for full catalog of: AI/Agents, web frameworks, ORMs, CLI tools, testing, async runtimes, task queues, debug tools

## Verification

- [ ] `mypy` / `pyright` passes with strict mode on type hints
- [ ] FastAPI endpoints respond with correct status codes and validation
- [ ] Async functions don't block the event loop (no `time.sleep`, no sync HTTP)
- [ ] `asyncio.gather` uses `return_exceptions=True` for parallel tasks
- [ ] Pydantic models use `model_config` (not `class Config`)
- [ ] All reference links resolve to existing files

## See Also
- `testing-standards` — pytest patterns, fixtures, mocks
- `deployment-patterns` — Docker, Railway for Python apps
- `data-analysis` — pandas, polars, numpy workflows
- `api-patterns` — REST design conventions with FastAPI
- `database-patterns` — SQLAlchemy, migrations, connection pooling
