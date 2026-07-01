---
name: python-patterns
description: "Modern Python 3.10+ patterns — type hints (PEP 604 union syntax), FastAPI with Pydantic v2, async/await with asyncio, error handling with specific exception types, and idiomatic patterns for the user's stack (FastAPI, SQLAlchemy 2.0 async, Streamlit). Use when writing or reviewing Python code that uses modern features. Triggers: python, fastapi, pydantic, sqlalchemy, async, type hints, asyncio, streamlit."
triggers:
  - "python-patterns"
  - "python patterns"
  - "when to use python patterns"
  - "how to python patterns"
  - "python patterns examples"
  - "python patterns pattern"
applies_to:
  - "main-coordinator"
---


# Python Patterns — Modern Python 3.10+ Idioms

## When to use this

Load this skill when:
- Writing Python 3.10+ code with modern features (match statements, type unions)
- Building FastAPI endpoints with Pydantic v2 models
- Working with asyncio (async/await, async generators)
- Reviewing Python code for idiomatic patterns
- Working with Streamlit apps

Do NOT use this skill when:
- Python 2 or pre-3.10 code (different patterns)
- Performance-critical code (use `cs-fundamentals` and `performance-optimization` skills)
- Security-focused code (use `secure-coding` skill — covers OWASP)
- Database migrations (use `database-patterns` skill)

---

## Core patterns

### 1. Type hints — modern style (PEP 604)

**Prefer union syntax `|` over `Union[X, Y]`**:

```python
# GOOD (3.10+)
def get_user(user_id: int | str) -> User | None:
    ...

# AVOID (older)
from typing import Union, Optional
def get_user(user_id: Union[int, str]) -> Optional[User]:
    ...
```

**Use `|` for type aliases**, not `TypeAlias`:

```python
# GOOD (3.10+)
UserId = int | str
UserDict = dict[str, User]

# AVOID
from typing import TypeAlias
UserId: TypeAlias = int | str
```

**Built-in generics** (3.9+), no `from typing import`:

```python
# GOOD
def process(items: list[int]) -> dict[str, int]:
    ...

# AVOID
from typing import List, Dict
def process(items: List[int]) -> Dict[str, int]:
    ...
```

### 2. Match statements (3.10+)

Use for structural pattern matching instead of long if/elif chains:

```python
# GOOD
def handle_response(response: dict) -> str:
    match response:
        case {"status": "ok", "data": data}:
            return f"OK: {data}"
        case {"status": "error", "code": 404}:
            return "Not found"
        case {"status": "error", "code": code} if code >= 500:
            return f"Server error {code}"
        case _:
            return "Unknown"

# AVOID
def handle_response(response):
    if response.get("status") == "ok":
        return f"OK: {response.get('data')}"
    elif response.get("status") == "error":
        if response.get("code") == 404:
            return "Not found"
        elif response.get("code") >= 500:
            return f"Server error {response.get('code')}"
    return "Unknown"
```

### 3. Exception groups (3.11+)

Use `ExceptionGroup` when raising multiple exceptions at once:

```python
# GOOD (3.11+)
def validate_all(data: list[dict]) -> None:
    errors = []
    for item in data:
        try:
            validate(item)
        except ValidationError as e:
            errors.append(e)
    if errors:
        raise ExceptionGroup("Validation failed", errors)

# Catch with except*
try:
    validate_all(data)
except* ValueError as eg:
    for e in eg.exceptions:
        log(f"Value error: {e}")
```

### 4. FastAPI + Pydantic v2

**Pydantic v2 syntax** (faster, stricter than v1):

```python
from pydantic import BaseModel, Field, ConfigDict

class UserCreate(BaseModel):
    model_config = ConfigDict(strict=True)  # v2: no implicit coercion

    email: str = Field(..., min_length=3, max_length=255)
    age: int = Field(..., ge=0, le=150)
    role: Literal["student", "teacher", "admin"] = "student"
```

**FastAPI endpoint with proper types**:

```python
from fastapi import FastAPI, Depends, HTTPException, status
from typing import Annotated

app = FastAPI()

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]) -> User:
    user = await db.get_user_by_token(token)
    if not user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return user

@app.post("/users", status_code=status.HTTP_201_CREATED)
async def create_user(
    user: UserCreate,
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    if current_user.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Admin only")
    return await db.create_user(user)
```

### 5. Async patterns

**Don't mix sync and async I/O**:

```python
# BAD — blocks event loop
async def get_user(user_id: int) -> User:
    user = db.query(...).first()  # sync I/O in async function
    return user

# GOOD
async def get_user(user_id: int) -> User:
    user = await db.fetch_one(...)  # async I/O
    return user
```

**Use `asyncio.gather` for parallel operations**:

```python
# GOOD
async def get_dashboard(user_id: int) -> Dashboard:
    user, stats, notifications = await asyncio.gather(
        db.get_user(user_id),
        db.get_stats(user_id),
        db.get_notifications(user_id),
    )
    return Dashboard(user=user, stats=stats, notifications=notifications)
```

**Async context managers and generators**:

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_db_session():
    session = Session()
    try:
        yield session
    finally:
        await session.close()

# Usage
async with get_db_session() as session:
    await session.execute(...)
```

### 6. Error handling

**Specific exceptions, not bare `except:`**:

```python
# GOOD
try:
    result = await fetch(url)
except TimeoutError:
    log.warning(f"Timeout: {url}")
    return None
except HTTPStatusError as e:
    if e.status_code == 404:
        return None
    raise

# BAD
try:
    result = await fetch(url)
except:
    pass  # swallows everything
```

**Use `raise from` to preserve cause**:

```python
# GOOD
try:
    data = json.loads(text)
except json.JSONDecodeError as e:
    raise ValueError(f"Invalid JSON from {url}") from e
```

### 7. SQLAlchemy 2.0 async style

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy import select

engine = create_async_engine(DATABASE_URL)

async def get_user_by_email(session: AsyncSession, email: str) -> User | None:
    stmt = select(User).where(User.email == email)
    result = await session.execute(stmt)
    return result.scalar_one_or_none()

# Session lifecycle
async with AsyncSession(engine) as session:
    user = await get_user_by_email(session, "[email protected]")
    print(user)
```

---

## What NOT to include (per research)

These are auto-detected by the agent — don't restate:

- PEP 8 basics (indentation, naming)
- "Use type hints" (universal)
- Basic syntax (the model knows)
- `print()` debugging advice (covered in `systematic-debugging` skill)
- Standard library reference (model has training data)

---

## Cross-references

- `skills/fastapi-patterns` (if exists) — for deeper FastAPI specifics
- `skills/sql-safety` — for parameterized queries
- `skills/secure-coding` — for OWASP-aware Python patterns
- `rules/sql-safety.md` — Postgres type discipline
- `agents/code-reviewer.md` — reviews Python code
- `agents/cybersecurity.md` — security-focused Python review

---

## Version notes

- **3.10**: match statements, `X | Y` union syntax, parameter specifiers
- **3.11**: `ExceptionGroup`, `except*`, `TaskGroup`, `tomllib`
- **3.12**: type parameter syntax (`class Foo[T]:`), `TYPE_CHECKING` improvements

User's stack uses 3.10 (PRIA) and 3.12 (Math Platform). Code in those projects should target the respective version's feature set — don't use 3.12-only syntax in PRIA.