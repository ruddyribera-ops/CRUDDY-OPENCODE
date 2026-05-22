# Python Code Examples

## Type Hints (Python 3.10+)
```python
# Use built-in types (no typing.List/Dict in 3.10+)
def process_items(items: list[str], config: dict[str, int]) -> bool: ...

# Union with | operator
def fetch(url: str, timeout: int | None = None) -> str | None: ...

# TypeAlias for complex types
type UserId = int
type UserMap = dict[UserId, "User"]
```

## Dataclasses
```python
from dataclasses import dataclass, field

@dataclass
class User:
    id: int
    name: str
    email: str
    roles: list[str] = field(default_factory=list)
    active: bool = True

@dataclass(frozen=True)
class Config:
    host: str
    port: int = 8000
    debug: bool = False
```

## Pydantic Models
```python
from pydantic import BaseModel, Field, field_validator

class CreateUserRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str
    age: int = Field(ge=0, le=150)

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        if "@" not in v: raise ValueError("Invalid email")
        return v.lower()

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    model_config = {"from_attributes": True}  # ORM mode
```

## FastAPI Patterns
```python
from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="My API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/users/{user_id}")
async def get_user(user_id: int) -> UserResponse:
    user = await db.get_user(user_id)
    if not user: raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)

@app.get("/users")
async def list_users(skip: int = Query(0, ge=0), limit: int = Query(20, ge=1, le=100),
                     active: bool = True) -> list[UserResponse]:
    return await db.list_users(skip=skip, limit=limit, active=active)

async def get_db():
    db = Database()
    try: yield db
    finally: await db.close()

@app.post("/users")
async def create_user(data: CreateUserRequest, db: Database = Depends(get_db)) -> UserResponse:
    return await db.create_user(data)
```

## Async/Await Patterns
```python
import asyncio, httpx

# Parallel async calls
async def fetch_all(urls: list[str]) -> list[str]:
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        return [r.text if isinstance(r, httpx.Response) else str(r) for r in responses]

# Timeout wrapper
async def with_timeout(coro, seconds: float):
    try: return await asyncio.wait_for(coro, timeout=seconds)
    except asyncio.TimeoutError: raise TimeoutError(f"Timed out after {seconds}s")

# Async context manager
class AsyncDatabase:
    async def __aenter__(self):
        self.conn = await create_connection(); return self
    async def __aexit__(self, exc_type, exc_val, exc_tb): await self.conn.close()
```

## Error Handling
```python
class AppError(Exception):
    def __init__(self, message: str, code: str = "UNKNOWN"):
        self.message, self.code = message, code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: int):
        super().__init__(f"{resource} {id} not found", code="NOT_FOUND")

class ValidationError(AppError):
    def __init__(self, field: str, reason: str):
        super().__init__(f"Invalid {field}: {reason}", code="VALIDATION")

# Result pattern (like Rust)
from dataclasses import dataclass
from typing import Generic, TypeVar
T = TypeVar("T")

@dataclass
class Result(Generic[T]):
    value: T | None = None
    error: str | None = None
    @property
    def ok(self) -> bool: return self.error is None

def divide(a: float, b: float) -> Result[float]:
    if b == 0: return Result(error="Division by zero")
    return Result(value=a / b)
```

## Decorators
```python
import functools, asyncio

def retry(max_attempts: int = 3, delay: float = 1.0):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try: return await func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1: raise
                    await asyncio.sleep(delay * (2 ** attempt))
        return wrapper
    return decorator
```

## List/Dict Comprehensions
```python
active_names = [u.name for u in users if u.active]  # Filter + transform
users_by_id = {u.id: u for u in users}                # Dict from list

from collections import defaultdict
by_role: dict[str, list[User]] = defaultdict(list)
for user in users: by_role[user.role].append(user)

# Walrus operator
results = [processed for item in items if (processed := expensive_transform(item)) is not None]
```

## Context Managers
```python
from contextlib import contextmanager, asynccontextmanager

@contextmanager
def timer(label: str):
    import time; start = time.perf_counter(); yield
    elapsed = time.perf_counter() - start; print(f"{label}: {elapsed:.2f}s")

@asynccontextmanager
async def managed_transaction(db):
    tx = await db.begin()
    try: yield tx; await tx.commit()
    except Exception: await tx.rollback(); raise
```

## Environment & Config
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str; secret_key: str; debug: bool = False; port: int = 8000
    model_config = {"env_file": ".env"}

settings = Settings()  # Auto-loads from .env and environment
```

## Anti-Patterns
- **Global vars instead of Pydantic settings** — use `BaseSettings` for typed config
- **Mixing async/sync** — never `requests.get()` in async functions (blocks event loop)
- **Unbounded list comps on large data** — use generators/pagination instead
- **`Optional[X]` when field is required** — use `X` for required, `X | None` for optional
