---
name: python-patterns
description: Modern Python patterns — FastAPI, Pydantic v2, SQLAlchemy 2.0 async, type hints, testing with pytest. Covers project structure, dependency injection, and async patterns.
triggers: python, fastapi, pydantic, sqlalchemy, async, pytest, type-hints
auto_load: code-builder
---

# Python Patterns

## FastAPI
- Use `Annotated` for dependency injection (Pydantic v2 style)
- Path operations: `@router.get()`, not `@app.get()` — use APIRouter
- Response model: always define Pydantic response models, never return dicts

## SQLAlchemy 2.0
- Async session: `async with async_session_maker() as session:`
- `select()` statement style, not legacy `Query` API
- `joinedload()` for eager loading, avoid N+1

## Type Hints
- Always annotate function signatures (parameters + return type)
- Use `Self` return type for class methods
- `type hint` everything — no untyped dicts/lists as parameters

## Testing
- `pytest` + `pytest-asyncio` for async tests
- Fixtures for DB session, test client, auth headers
- Factory boy for test data

## Project Structure
- `src/` package, not flat files
- `src/config.py` for settings (pydantic-settings)
- `src/models/`, `src/routes/`, `src/services/` separation
