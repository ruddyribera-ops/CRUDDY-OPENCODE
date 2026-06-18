# Go / Fiber — High-Performance Web Framework

Fiber is an Express-inspired web framework built on Fasthttp (the fastest HTTP engine for Go).

## Quick Reference

| Feature | Package |
|---------|---------|
| Web framework | `github.com/gofiber/fiber/v2` |
| ORM | `github.com/go-pg/pg/v10` or `github.com/jmoiron/sqlx` |
| Validation | `github.com/go-playground/validator` |
| Auth JWT | `github.com/golang-jwt/jwt/v5` |
| Migration | `github.com/golang-migrate/migrate` |

## Project Structure (Go/Fiber)

```
backend/
├── cmd/server/main.go          # Entry point
├── internal/
│   ├── config/                 # Environment config
│   │   └── config.go
│   ├── handlers/              # HTTP handlers (controllers)
│   │   ├── user.go
│   │   └── order.go
│   ├── services/              # Business logic
│   │   ├── user.go
│   │   └── order.go
│   ├── repository/            # Data access
│   │   ├── user.go
│   │   └── order.go
│   ├── models/                # Domain models
│   │   └── models.go
│   ├── middleware/             # Auth, logging, CORS
│   │   └── middleware.go
│   └── errors/                 # Typed errors
│       └── errors.go
├── migrations/
├── go.mod
└── go.sum
```

## Setup & Config

```go
package main

import (
    "os"
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "github.com/gofiber/fiber/v2/middleware/logger"
    "github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
    app := fiber.New(fiber.Config{
        ErrorHandler: customErrorHandler,
    })

    // Global middleware
    app.Use(recover.New())
    app.Use(logger.New())
    app.Use(cors.New(cors.Config{
        AllowOrigins: os.Getenv("CORS_ORIGINS"),
        AllowMethods: "GET,POST,PUT,DELETE,PATCH",
        AllowHeaders: "Origin,Content-Type,Accept,Authorization",
    }))

    // Routes
    setupRoutes(app)

    // Graceful shutdown
    app.Listen(":" + os.Getenv("PORT"))
}
```

## Routing & Handlers

```go
// Routes
app.Get("/health", handlers.Health)
app.Post("/api/users", handlers.CreateUser)
app.Get("/api/users/:id", handlers.GetUser)
app.Put("/api/users/:id", handlers.UpdateUser)
app.Delete("/api/users/:id", handlers.DeleteUser)

// Handler
func GetUser(c *fiber.Ctx) error {
    id := c.Params("id")
    user, err := services.GetUserByID(id)
    if err != nil {
        return err.NotFound("user not found")
    }
    return c.JSON(user)
}
```

## Middleware

```go
// Auth middleware
func AuthRequired() fiber.Handler {
    return func(c *fiber.Ctx) error {
        header := c.Get("Authorization")
        if header == "" {
            return fiber.NewError(fiber.StatusUnauthorized, "missing token")
        }
        tokenStr := strings.TrimPrefix(header, "Bearer ")
        claims, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
            return []byte(os.Getenv("JWT_SECRET")), nil
        })
        if err != nil || !claims.Valid {
            return fiber.NewError(fiber.StatusUnauthorized, "invalid token")
        }
        c.Locals("userID", claims["sub"])
        return c.Next()
    }
}

// Usage
app.Get("/api/profile", AuthRequired(), handlers.GetProfile)
```

## Database (sqlx)

```go
// internal/repository/user.go
package repository

import (
    "github.com/jmoiron/sqlx"
    "yourapp/internal/models"
)

type UserRepository struct {
    db *sqlx.DB
}

func (r *UserRepository) FindByID(id string) (*models.User, error) {
    var user models.User
    err := r.db.Get(&user, "SELECT * FROM users WHERE id = $1", id)
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) Create(user *models.User) error {
    query := `INSERT INTO users (id, name, email, created_at)
              VALUES ($1, $2, $3, NOW()) RETURNING created_at`
    return r.db.QueryRow(query, user.ID, user.Name, user.Email).Scan(&user.CreatedAt)
}
```

## Validation

```go
import "github.com/go-playground/validator"

type CreateUserInput struct {
    Name  string `json:"name" validate:"required,min=2,max=100"`
    Email string `json:"email" validate:"required,email"`
    Age   int    `json:"age" validate:"gte=0,lte=150"`
}

func CreateUser(c *fiber.Ctx) error {
    var input CreateUserInput
    if err := c.BodyParser(&input); err != nil {
        return fiber.NewError(fiber.StatusBadRequest, "invalid request body")
    }

    validate := validator.New()
    if err := validate.Struct(input); err != nil {
        return fiber.NewError(fiber.StatusUnprocessableEntity, err.Error())
    }

    // Proceed...
    return nil
}
```

## Typed Errors

```go
// internal/errors/errors.go
type AppError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Status  int    `json:"-"`
}

func (e *AppError) Error() string {
    return e.Message
}

func NotFound(msg string) *AppError {
    return &AppError{Code: "NOT_FOUND", Message: msg, Status: 404}
}

func BadRequest(msg string) *AppError {
    return &AppError{Code: "BAD_REQUEST", Message: msg, Status: 400}
}

func Internal(msg string) *AppError {
    return &AppError{Code: "INTERNAL_ERROR", Message: msg, Status: 500}
}

// Global error handler
func customErrorHandler(c *fiber.Ctx, err error) error {
    if e, ok := err.(*AppError); ok {
        return c.Status(e.Status).JSON(fiber.Map{
            "error": fiber.Map{"code": e.Code, "message": e.Message},
        })
    }
    return c.Status(500).JSON(fiber.Map{
        "error": fiber.Map{"code": "INTERNAL_ERROR", "message": "unexpected error"},
    })
}
```

## Testing

```go
// internal/handlers/user_test.go
func TestGetUser(t *testing.T) {
    app := fiber.New()
    setupRoutes(app)

    req := httptest.NewRequest("GET", "/api/users/123", nil)
    resp, err := app.Test(req)

    assert.NoError(t, err)
    assert.Equal(t, 200, resp.StatusCode)
}
```

## Docker

```dockerfile
# Multi-stage build
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/server .
COPY --from=builder /app/migrations ./migrations
EXPOSE 8080
CMD ["./server"]
```

## Comparison: Fiber vs Express

| Aspect | Fiber | Express |
|--------|-------|---------|
| Language | Go | Node.js |
| Performance | ~3x faster | Baseline |
| Concurrency | Goroutines | Event loop |
| Memory | Lower | Higher |
| Ecosystem | Growing | Massive |

## Resources

- [awesome-fiber](https://github.com/gofiber/awesome-fiber)
- [gofiber.io/docs](https://docs.gofiber.io/)