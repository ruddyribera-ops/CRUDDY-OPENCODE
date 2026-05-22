# Python Ecosystem & Libraries

## AI & Agents
| Library | Purpose |
|---------|---------|
| langchain | Chain LLM calls, RAG, agents |
| pydantic-ai | Pydantic-native AI agent framework |
| crewai | Multi-agent orchestration |
| instructor | Structured LLM outputs via Pydantic |
| transformers | HuggingFace — 200K+ pretrained models |

## Web Frameworks (Async)
| Library | Purpose |
|---------|---------|
| FastAPI | Production async framework — Pydantic + OpenAPI |
| litestar | Alternative — layered architecture, DTOs, DI |
| starlette | Lightweight ASGI toolkit |
| reflex | Full-stack Python web apps |

## Web APIs (Sync)
| Library | Purpose |
|---------|---------|
| django-ninja | Django REST with Pydantic |
| django-rest-framework | Classic Django REST |

## ORM & Data Access
| Library | Purpose |
|---------|---------|
| sqlalchemy | The Python ORM — 2.0 async style |
| sqlmodel | SQLAlchemy + Pydantic merged |
| peewee | Lightweight ORM for SQLite |
| tortoise-orm | Async ORM for asyncio |
| beanie | MongoDB ODM for async |

## Data Validation
| Library | Purpose |
|---------|---------|
| pydantic | De facto validation lib |
| pandera | DataFrame validation |
| msgspec | Fast serialization (10-80x faster) |

## CLI Development
| Library | Purpose |
|---------|---------|
| typer | Build CLIs from type hints |
| click | Battle-tested CLI framework |
| rich | Terminal formatting |
| textual | TUI framework |

## Testing
| Library | Purpose |
|---------|---------|
| pytest | Default testing framework |
| tox | Test across Python versions |
| hypothesis | Property-based testing |
| vcr.py | Record/replay HTTP tests |

## Async Runtime
| Library | Purpose |
|---------|---------|
| asyncio | Built-in async standard |
| anyio | Backend-agnostic async |
| trio | Structured concurrency |
| aiohttp | Async HTTP client/server |
| httpx | Modern HTTP client |

## Task Queues
| Library | Purpose |
|---------|---------|
| celery | Distributed task queue |
| rq | Simple Redis-backed queue |
| huey | Lightweight task queue |
| dramatiq | Modern task queue |
| arq | async/await-first queue |

## Debugging & DevTools
| Library | Purpose |
|---------|---------|
| pdbpp | Enhanced pdb |
| ipdb | IPython-powered debugger |
| icecream | Zero-boilerplate `ic()` |
| py-spy | Sampling profiler |
| ruff | 100x faster linter+formatter |
| mypy | Static type checking |
| pyright | Microsoft's type checker |
| pre-commit | Git hooks framework |
