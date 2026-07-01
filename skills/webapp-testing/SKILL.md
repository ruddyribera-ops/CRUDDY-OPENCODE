---
name: webapp-testing
description: "Web application testing patterns using Playwright — UI selectors, dynamic content, cold starts, browser automation, end-to-end flows. Use when building or testing web applications. Triggers: webapp testing, Playwright, UI test, end-to-end test, e2e, browser automation, DOM selector, click test."
triggers:
  - "webapp-testing"
  - "webapp testing"
  - "when to use webapp testing"
  - "how to webapp testing"
  - "webapp testing examples"
  - "webapp testing pattern"
applies_to:
  - "main-coordinator"
---


# Webapp Testing

## When to use this

Load this skill when building end-to-end tests for web applications, automating browser workflows, testing multi-step user journeys, or debugging flaky tests caused by timing issues.

---

## Core Principles

1. **Use data-testid attributes instead of CSS selectors** — Refactoring CSS classes or HTML structure breaks tests that rely on CSS selectors. `data-testid` survives refactors and signals intent.

2. **Wait for conditions, never hard-coded sleep** — `page.waitForSelector`, `page.waitForResponse`, `page.waitForLoadState` are deterministic. `sleep(5000)` is a race condition waiting to happen.

3. **Cold starts are real — build in retries** — Serverless apps, containers, and slow APIs cause initial failures that succeed on retry. Tests that fail on the first run but pass on retry are not flaky — they are revealing a real cold-start issue.

4. **Multi-tab and multi-context patterns require explicit waits** — When opening a new tab, wait for the tab to load and for the URL to match. Do not assume the new tab is the active one.

5. **Test behavior, not implementation** — Test what the user sees and can do, not the internal state of components. Avoid testing component props or internal variables.

6. **Isolate tests from each other** — Each test should set up its own data and clean up after itself. Shared state between tests causes interdependencies that make failures hard to diagnose.

7. **Run tests against a production-like environment** — Testing against a mocked backend misses integration bugs. Use real browsers against a staging environment with real (or test) data.

---

## Patterns

### Playwright MCP Integration

```typescript
// When using the Playwright MCP server in opencode,
// the MCP tool wraps Playwright's API. Usage pattern:

// Wait for element to be visible (recommended over waitForSelector)
await page.waitForSelector('[data-testid="submit-button"]', { state: 'visible' });

// Click using test ID
await page.click('[data-testid="submit-button"]');

// Fill form using test ID
await page.fill('[data-testid="email-input"]', 'user@example.com');

// Verify element text
const errorMsg = await page.textContent('[data-testid="error-message"]');
expect(errorMsg).toContain('Invalid email');
```

### DOM Selectors (Best to Worst)

```typescript
// BEST: data-testid — stable, intentional, survives CSS/HTML refactors
await page.click('[data-testid="login-submit"]');

// SECOND BEST: Semantic role — tests accessibility, matches real usage
await page.click('button[type="submit"]');
await page.click('input[placeholder="Search..."]');
await page.click('text="Sign in"');  // text content

// THIRD: ARIA labels — tests accessibility
await page.click('[aria-label="Close dialog"]');

// WORST: CSS classes and XPath — break on refactor, overly specific
await page.click('.btn-primary.submit-btn');    // CSS class
await page.locator('xpath=//button[contains(@class,"submit")]');  // XPath
```

### Waiting Strategies (No Hard Sleeps)

```typescript
// WAIT for element: visible, attached, hidden, detached
await page.waitForSelector('[data-testid="dashboard"]', { state: 'visible', timeout: 10000 });

// WAIT for network response (API calls)
await page.waitForResponse(
  response => response.url().includes('/api/users') && response.status() === 200,
  { timeout: 10000 }
);

// WAIT for navigation (full page load)
await page.waitForLoadState('networkidle');  // all network activity settled

// WAIT for URL change
await page.waitForURL('**/dashboard/**', { timeout: 10000 });

// WAIT for function to return true (custom condition)
await page.waitForFunction(() => {
  return document.querySelector('[data-testid="status"]')?.textContent === 'Ready';
}, { timeout: 10000 });

// NEVER do this:
await page.sleep(5000);  // Race condition — use explicit waits instead
```

### Cold Start Tolerance (Retries)

```typescript
import { test, expect } from '@playwright/test';

test('user can login', { retries: 2 });  // Playwright retries on failure

test('dashboard loads after login', async ({ page }) => {
  // Use expect with a timeout instead of a single assertion
  await expect(page).toHaveURL('**/dashboard/**', { timeout: 15000 });

  // Retry until element appears (up to 15 seconds)
  await expect(page.locator('[data-testid="welcome-message"]')).toBeVisible({ timeout: 15000 });
});
```

### Multi-Tab / Multi-Window Patterns

```typescript
test('opens user profile in new tab', async ({ page }) => {
  // Capture the new page before clicking
  const [newPage] = await Promise.all([
    page.context().waitForEvent('page'),  // wait for new tab
    page.click('[data-testid="user-link"]'),  // trigger opens new tab
  ]);

  // Wait for new tab to load
  await newPage.waitForLoadState('domcontentloaded');
  await newPage.waitForURL('**/users/**');

  // Work in the new tab
  await newPage.fill('[data-testid="status-input"]', 'Available');

  // Close the new tab
  await newPage.close();

  // Original page is still open
  await expect(page.locator('[data-testid="back-link"]')).toBeVisible();
});
```

### Multi-Context (Isolated Browser Contexts)

```typescript
test('two users can edit simultaneously without interference', async ({ browser }) => {
  // Create two separate browser contexts (like incognito windows)
  const context1 = await browser.newContext();
  const context2 = await browser.newContext();

  const page1 = await context1.newPage();
  const page2 = await context2.newPage();

  // User 1 edits document A
  await page1.goto('/docs/A');
  await page1.fill('[data-testid="doc-title"]', 'User 1 Version');

  // User 2 edits document A simultaneously
  await page2.goto('/docs/A');
  await page2.fill('[data-testid="doc-title"]', 'User 2 Version');

  // Verify they don't see each other's changes until refresh
  const title1 = await page1.locator('[data-testid="doc-title"]').inputValue();
  const title2 = await page2.locator('[data-testid="doc-title"]').inputValue();

  expect(title1).toBe('User 1 Version');
  expect(title2).toBe('User 2 Version');

  await context1.close();
  await context2.close();
});
```

### End-to-End Flow: Login + Dashboard

```typescript
import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to app — clear cookies and set up fresh state
    await page.context().clearCookies();
    await page.goto('/');
  });

  test('successful login shows dashboard', async ({ page }) => {
    await page.fill('[data-testid="email-input"]', 'testuser@example.com');
    await page.fill('[data-testid="password-input"]', 'correct-password');
    await page.click('[data-testid="login-button"]');

    // Wait for redirect to dashboard
    await page.waitForURL('**/dashboard/**', { timeout: 10000 });

    // Verify dashboard content loaded
    await expect(page.locator('[data-testid="welcome-banner"]')).toBeVisible();
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
  });

  test('failed login shows error message', async ({ page }) => {
    await page.fill('[data-testid="email-input"]', 'testuser@example.com');
    await page.fill('[data-testid="password-input"]', 'wrong-password');
    await page.click('[data-testid="login-button"]');

    // Wait for error message
    await expect(page.locator('[data-testid="error-alert"]')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('[data-testid="error-alert"]')).toContainText('Invalid credentials');

    // Verify user is NOT redirected
    await expect(page).toHaveURL(/\/login/);
  });
});
```

### File Upload Testing

```typescript
test('user can upload a profile photo', async ({ page }) => {
  await page.goto('/settings/profile');

  // Set up file chooser listener before clicking
  const [fileChooser] = await Promise.all([
    page.waitForEvent('filechooser'),
    page.click('[data-testid="upload-photo-button"]'),
  ]);

  // Upload test file
  await fileChooser.setFiles('./fixtures/test-photo.jpg');

  // Verify preview appears
  await expect(page.locator('[data-testid="photo-preview"]')).toBeVisible();

  // Submit and verify success
  await page.click('[data-testid="save-button"]');
  await expect(page.locator('[data-testid="success-message"]')).toContainText('Photo updated');
});
```

### API Testing with Playwright (Mocking Responses)

```typescript
test('displays user data from API', async ({ page }) => {
  // Intercept API response and mock it
  await page.route('/api/users/123', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        id: '123',
        name: 'Alice Smith',
        email: 'alice@example.com',
      }),
    });
  });

  await page.goto('/users/123');

  // Verify mocked data is displayed
  await expect(page.locator('[data-testid="user-name"]')).toContainText('Alice Smith');
  await expect(page.locator('[data-testid="user-email"]')).toContainText('alice@example.com');
});
```

---

## Anti-Patterns

- **Hard-coded `sleep(N)`** — The app might be slow today and fast tomorrow. Tests that rely on fixed delays fail non-deterministically. Use explicit waits for conditions.

- **CSS class selectors** — When a designer renames `.btn-primary` to `.btn-submit`, your tests break even though the app works perfectly.

- **Testing implementation details** — Testing that a React component has `state = { loading: true }` couples your tests to internal implementation. Test what the user sees and does.

- **Not cleaning up between tests** — Failing to reset state causes test interdependencies. A test that passes when run alone but fails when run with others is a state leakage bug.

- **Missing test isolation** — Two tests that create a user named "Alice" will collide. Each test needs unique identifiers or a database reset.

- **Not waiting for network idle** — Clicking a button that triggers an API call and immediately checking the result races against the network. Wait for the response or for the DOM to reflect the change.

- **Ignoring console errors** — Playwright can capture console errors. A test that passes with console errors is hiding real bugs.

---

## Quick Reference

| Pattern | Correct | Anti-Pattern |
|---------|---------|--------------|
| Selector | `[data-testid="btn"]` | `.btn-primary`, `xpath=//button` |
| Waiting | `waitForSelector` | `sleep(5000)` |
| Click | `page.click(testid)` | `page.click('.class')` |
| Navigation | `waitForURL('**/path')` | `sleep + check URL` |
| Error check | `expect(alert).toBeVisible` | Ignore console errors |
| Test isolation | Each test creates own data | Shared setup |

### Playwright Test Config (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,  // 30s per test
  retries: 2,       // Retry flaky tests twice
  workers: process.env.CI ? 2 : undefined,  // Parallel on CI
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',  // Capture trace on first retry
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
});
```

### Console Error Capture

```typescript
test('page has no console errors', async ({ page }) => {
  const errors: string[] = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
    }
  });

  await page.goto('/');
  // Interact with the page...

  // Fail test if any console errors were emitted
  expect(errors).toHaveLength(0);
});
```

---

## Companion Scripts and References

### Python Examples (`references/`)

The `references/` directory contains Python Playwright examples from the Anthropic skills collection:

| File | Purpose |
|------|---------|
| `console_logging.py` | Captures browser console logs during test execution |
| `element_discovery.py` | Dynamic element discovery and selector strategies |
| `static_html_automation.py` | Automation patterns for static HTML pages |

**Attribution:** These examples are from [anthropics/skills](https://github.com/anthropics/skills) (MIT licensed). See `LICENSE.txt` for full attribution.

### Server Lifecycle Script (`scripts/`)

| File | Purpose |
|------|---------|
| `with_server.py` | Manages local web server lifecycle for testing — starts/stops server, waits for readiness, handles port allocation |

### Testing Anti-Patterns (`references/testing-anti-patterns.md`)

From [obra/superpowers](https://github.com/obra/superpowers) — strict TDD anti-patterns including:

- **Iron Laws:** Never test mock behavior, never add test-only methods to production classes, never mock without understanding dependencies
- **Anti-Pattern 1:** Testing mock existence instead of real component behavior
- **Anti-Pattern 2:** Test-only methods in production classes (use test utilities instead)
- **Anti-Pattern 3:** Mock without understanding dependencies
- **Gate function:** Before asserting on any mock element, ask "Am I testing real component behavior or just mock existence?"

See `references/testing-anti-patterns.md` for the full 299-line reference.
