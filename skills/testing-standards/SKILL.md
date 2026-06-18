---
name: testing-standards
description: Testing patterns, TDD approach, mocking, coverage standards, and test architecture for full-stack apps. Python (pytest) and TypeScript (vitest/jest) focused. MANDATORY: write tests BEFORE implementation code (red-green-refactor). Never declare done with 0% coverage on new features.
triggers: [test, pytest, jest, vitest, coverage, tdd, mock, unittest, e2e, integration-test, unit-test, test-suite, test-file, assertion, describe, it, expect, assert, before-each, after-each, setup, teardown, fixture, spy, stub, snapshot, cypress, playwright, testing-library, react-testing-library]
auto_load: code-builder
---

# Testing Standards

## ⚠️ MANDATORY TDD ENFORCEMENT (CODE-001 Gene)

**For EVERY new feature, you MUST follow red-green-refactor:**

```
1. Write the test FIRST (it will fail — "red")
2. Write the minimum code to make it pass ("green")
3. Refactor for clarity ("refactor")
4. Repeat until feature is complete
```

**Why this matters (research):**
- "TDD prompting alone increased regressions (9.94%)" when models skip the test-first step (arxiv:2603.17973v1, Mar 2026)
- Without TDD, agents default to "do everything in one go" (Reddit/C Claude Code, Jul 2025)
- Test-first catches edge cases BEFORE they become bugs

**What "no excuse" means:**
- New feature = minimum 1 test covering the happy path
- Bug fix = test that reproduces the bug before fixing
- If you write implementation code before tests, you're doing it wrong

**Verification:** `pytest tests/` / `vitest` must pass before you declare done.

---

## Core Principles

1. **Test behavior, not implementation** — tests should break when behavior changes, not when code is refactored
2. **One assertion concept per test** — each test verifies one thing
3. **Fast feedback** — unit tests run in milliseconds, integration in seconds, e2e in minutes
4. **Deterministic** — same test, same result, every time (no flaky tests)

---

## 1. Test Pyramid

```
         ╱ e2e ╲          ← Few: critical user journeys (Cypress, Playwright)
        ╱ integration ╲    ← Some: API routes, DB queries, service boundaries
       ╱   unit tests   ╲   ← Many: functions, utilities, hooks, components
```

### Ratios

| Layer | Count | Speed | What to test |
|-------|-------|-------|-------------|
| Unit | 70%+ | < 1ms each | Pure functions, utils, hooks, validators, models |
| Integration | 20% | < 1s each | API routes, DB queries, service orchestration |
| E2E | < 10% | < 30s each | Critical user flows, auth, payments, core features |

---

## 2. Python Testing (pytest)

### Test Structure

```python
import pytest
from datetime import datetime

# ✅ CORRECT: Clean arrange-act-assert
def test_calculate_order_total_with_multiple_items():
    # Arrange
    items = [{"price": 10.00, "qty": 2}, {"price": 5.00, "qty": 3}]

    # Act
    total = calculate_total(items)

    # Assert
    assert total == 35.00
```

### Fixtures

```python
@pytest.fixture
def sample_user(db_session):
    """Create a user for tests. Cleaned up automatically by transaction rollback."""
    user = User(email="test@example.com", password_hash="hashed_pw")
    db_session.add(user)
    db_session.commit()
    return user

@pytest.fixture
def client():
    """FastAPI test client with clean DB per test."""
    app.dependency_overrides[get_db] = lambda: test_db_session
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()

# ✅ Use: test gets a FRESH user each time
def test_get_user_profile(client, sample_user):
    response = client.get(f"/users/{sample_user.id}")
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"
```

### Parametrize

```python
@pytest.mark.parametrize("email,expected", [
    ("user@example.com", True),
    ("not-an-email", False),
    ("", False),
    ("user+tag@example.com", True),
])
def test_email_validation(email, expected):
    assert is_valid_email(email) == expected
```

### Mocking

```python
# ✅ Use monkeypatch for simple cases, pytest-mock for complex
def test_send_welcome_email(monkeypatch):
    sent = []
    monkeypatch.setattr("app.email.send_email", lambda to, msg: sent.append((to, msg)))
    # ... test runs without actually sending email
    assert len(sent) == 1

# ✅ Async mocking with pytest-asyncio
@pytest.mark.asyncio
async def test_async_service(mocker):
    mock_result = {"id": "123"}
    mocker.patch("app.api.fetch_data", return_value=mock_result)
    result = await my_service.get_data()
    assert result["id"] == "123"
```

### Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_operation()
    assert result is not None
```

---

## 3. TypeScript Testing (vitest)

### Test Structure

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';

describe('calculateTotal', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('calculates total with discount', () => {
    const items = [{ price: 100, quantity: 2 }];
    const result = calculateTotal(items, { discount: 0.1 });
    expect(result).toBe(180); // 200 - 10%
  });

  it('throws on negative quantity', () => {
    expect(() => calculateTotal([{ price: 10, quantity: -1 }])).toThrow('invalid quantity');
  });
});
```

### Mocking

```typescript
// ✅ Module mock
vi.mock('../lib/email', () => ({
  sendEmail: vi.fn(),
}));

// ✅ Function mock
const mockFetch = vi.fn();
vi.stubGlobal('fetch', mockFetch);

// ✅ Partial mock
const mockDb = {
  findUser: vi.fn().mockResolvedValue({ id: '1', name: 'Test' }),
  saveUser: vi.fn().mockResolvedValue(true),
};
```

### React Testing Library

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
  it('submits form with valid data', async () => {
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText('Email'), 'user@test.com');
    await userEvent.type(screen.getByLabelText('Password'), 'password123');
    await userEvent.click(screen.getByRole('button', { name: 'Login' }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'user@test.com',
        password: 'password123',
      });
    });
  });

  it('shows validation errors for empty fields', async () => {
    render(<LoginForm onSubmit={vi.fn()} />);
    await userEvent.click(screen.getByRole('button', { name: 'Login' }));

    expect(screen.getByText('Email is required')).toBeInTheDocument();
    expect(screen.getByText('Password is required')).toBeInTheDocument();
  });
});
```

---

## 4. What to Test (and What NOT To)

### Test These

- Pure business logic (always first priority)
- Input validation (edge cases: empty, too long, invalid format)
- Error handling (what happens when DB is down, API returns 500)
- Auth boundaries (unauthenticated gets 401, unauthorized gets 403)
- State transitions (draft → published → archived)
- Data transformations (calculations, formatting, parsing)

### Don't Test These

- Framework internals (Express routing, React reconciliation, SQLAlchemy sessions)
- Third-party library behavior (axios, Prisma, date-fns — trust their tests)
- CSS/styling (snapshot tests for visual things are brittle)
- Implementation details (internal helper names, private methods)
- Configuration that doesn't change (env var loading)

---

## 5. Integration Test Patterns

### API Integration

```python
def test_create_order_flow(client, auth_headers, sample_products):
    # 1. Create order
    response = client.post("/orders", json={
        "items": [{"product_id": sample_products[0].id, "qty": 2}]
    }, headers=auth_headers)
    assert response.status_code == 201
    order_id = response.json()["id"]

    # 2. Verify order exists
    response = client.get(f"/orders/{order_id}", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["status"] == "pending"

    # 3. Verify stock decreased
    response = client.get(f"/products/{sample_products[0].id}", headers=auth_headers)
    assert response.json()["stock"] == sample_products[0].stock - 2
```

### Database Integration

```python
def test_user_can_only_see_own_orders(client, auth_headers_1, auth_headers_2):
    """Users cannot access other users' orders."""
    # Alice creates an order
    alice_resp = client.post("/orders", json={"items": [...]}, headers=auth_headers_1)
    alice_order_id = alice_resp.json()["id"]

    # Bob tries to see it — should fail
    bob_resp = client.get(f"/orders/{alice_order_id}", headers=auth_headers_2)
    assert bob_resp.status_code == 404  # Not 403 — don't reveal order exists
```

---

## 6. E2E Test Patterns

```typescript
import { test, expect } from '@playwright/test';

test('user can complete purchase flow', async ({ page }) => {
  // Navigate
  await page.goto('/products');

  // Add item to cart
  await page.click('[data-testid="add-to-cart-1"]');

  // Go to checkout
  await page.click('[data-testid="checkout"]');
  await page.fill('[name="email"]', 'user@test.com');
  await page.fill('[name="password"]', 'password123');
  await page.click('[data-testid="login"]');

  // Complete payment
  await page.fill('[name="card"]', '4242424242424242');
  await page.fill('[name="expiry"]', '12/28');
  await page.fill('[name="cvc"]', '123');
  await page.click('[data-testid="pay"]');

  // Verify success
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
});
```

---

## 7. Timer/Flake Anti-Pattern

```javascript
// ❌ BAD: Fixed wait — flaky under load
await new Promise(r => setTimeout(r, 2000));

// ✅ GOOD: Wait for actual condition
await page.waitForSelector('[data-testid="result"]', { timeout: 10000 });

// ✅ GOOD: Polling (Python)
from tenacity import retry, stop_after_attempt, wait_fixed

@retry(stop=stop_after_attempt(3), wait=wait_fixed(1))
def wait_for_condition():
    result = check_condition()
    assert result is not None, "Condition not met yet"
```

---

## 8. Verification Checklist

- [ ] Tests follow arrange-act-assert pattern
- [ ] Pure business logic has full coverage (happy + edge + error paths)
- [ ] **TDD enforced:** test written BEFORE implementation code (red-green-refactor)
- [ ] Mocked external services (email, payments, third-party APIs)
- [ ] No fixed timers / sleeps in tests
- [ ] Tests are deterministic (same result every run)
- [ ] Database tests use transactions/rollback (clean state per test)
- [ ] Auth tests cover: unauthenticated (401), unauthorized (403), valid
- [ ] E2E tests cover critical user journeys only
- [ ] Coverage >= 70% on business logic (not aiming for 100% overall)
- [ ] Tests run in CI before any deploy
