# Python Backend — FastAPI, Flask, Dash

Modern Python web frameworks for backend services.

## FastAPI (Async, High-Performance)

### Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app entry
│   ├── config.py            # Settings (Pydantic)
│   ├── models/              # SQLAlchemy or async SQLModel
│   │   └── models.py
│   ├── schemas/             # Pydantic request/response
│   │   └── schemas.py
│   ├── routers/             # API routes
│   │   ├── users.py
│   │   └── orders.py
│   ├── services/            # Business logic
│   │   └── users.py
│   ├── db/                 # Database session
│   │   └── session.py
│   └── errors.py            # Custom exceptions
├── migrations/
├── requirements.txt
└── Dockerfile
```

### FastAPI App

```python
# app/main.py
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.config import settings
from app.routers import users, orders

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await db.connect()
    yield
    # Shutdown
    await db.disconnect()

app = FastAPI(
    title="My API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router, prefix="/api")
app.include_router(orders.router, prefix="/api")
```

### Pydantic Schemas

```python
# app/schemas/schemas.py
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserResponse(UserBase):
    id: str
    created_at: datetime
    class Config:
        from_attributes = True

class OrderItem(BaseModel):
    product_id: str
    quantity: int = Field(..., gt=0)

class OrderCreate(BaseModel):
    items: list[OrderItem]
```

### Async Routes

```python
# app/routers/users.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.db import get_db
from app.services import users as user_service
from app.schemas import UserCreate, UserResponse

router = APIRouter()

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    data: UserCreate,
    db: AsyncSession = Depends(get_db),
):
    user = await user_service.create_user(db, data)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    return user

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    user = await user_service.get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Async SQLAlchemy

```python
# app/db/session.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
)

async_session = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

async def get_db():
    async with async_session() as session:
        yield session
```

## Flask (Micro, Flexible)

### Flask App

```python
# app.py
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS

app = Flask(__name__)
app.config.from_object("config.Config")

db = SQLAlchemy(app)
migrate = Migrate(app, db)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Routes
@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

@app.route("/api/users", methods=["POST"])
def create_user():
    data = request.get_json()
    user = User(name=data["name"], email=data["email"])
    db.session.add(user)
    db.session.commit()
    return jsonify({"id": user.id, "name": user.name}), 201

# Error handlers
@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Not found"}), 404
```

### Flask Blueprints

```python
# app/users/routes.py
from flask import Blueprint
from . import db

bp = Blueprint("users", __name__, url_prefix="/api/users")

@bp.route("/", methods=["GET"])
def list_users():
    users = User.query.all()
    return jsonify([{"id": u.id, "name": u.name} for u in users])
```

## Dash (Data Apps)

```python
# app.py
import dash
from dash import dcc, html, Input, Output, State
import pandas as pd

app = dash.Dash(__name__)

app.layout = html.Div([
    html.H1("Sales Dashboard"),
    dcc.Dropdown(
        id="region-selector",
        options=[
            {"label": "North", "value": "north"},
            {"label": "South", "value": "south"},
        ],
        value="north",
    ),
    dcc.Graph(id="sales-chart"),
])

@app.callback(
    Output("sales-chart", "figure"),
    Input("region-selector", "value"),
)
def update_chart(region):
    df = pd.read_csv(f"sales_{region}.csv")
    return {
        "data": [{"x": df.date, "y": df.sales, "type": "line"}],
        "layout": {"title": f"Sales - {region.title()}"},
    }
```

## Deployment

```dockerfile
# FastAPI + Uvicorn
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## FastAPI vs Flask vs Dash

| Framework | Best For | Async | Complexity |
|----------|----------|-------|------------|
| **FastAPI** | APIs, microservices, async I/O | ✅ Native | Medium |
| **Flask** | Simple APIs, CMS, flexible apps | ❌ | Low |
| **Dash** | Data dashboards, analytics | ❌ | Low |

## Resources

- [awesome-fastapi](https://github.com/mjhea0/awesome-fastapi)
- [awesome-flask](https://github.com/mjhea0/awesome-flask)