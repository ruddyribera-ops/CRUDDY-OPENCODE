# Adaptive UI Patterns — Detailed Code Examples

## Rule 1 — Never time.sleep in UI tests

```python
# BAD — flakes on cold start
import time
time.sleep(5)  # Too slow when warm, too fast when cold

# GOOD — wait for the element to prove it's ready
page.wait_for_selector('#student-table tbody tr', timeout=15000)

# GOOD — wait for a specific piece of evidence
page.wait_for_selector('.stMetric label', timeout=20000)
```

## Rule 2 — Use anchored selectors, not positional ones

```python
# BAD — breaks when rows are reordered
table_rows = page.query_selector_all('table tbody tr')
third_row = table_rows[2]  # Assumes row 3 always exists

# GOOD — find by stable content anchor
third_row = page.query_selector(
    'table tbody tr:has(td:text-is("student@school.bo"))'
)
```

## Rule 3 — Streamlit-specific patterns

### Streamlit login DOM survival
```python
USERNAME_INPUT = 'input[type="text"]'
PASSWORD_INPUT = 'input[type="password"]'
SUBMIT_BUTTON = 'button:has-text("Ingresar")'
ERROR_MESSAGE = '.stAlert:has-text("incorrecta")'

# Wait for the form to be fully rendered
page.wait_for_selector(USERNAME_INPUT, timeout=20000)

# Streamlit's hash-based navigation reloads the DOM on route change
if route == "dashboard":
    page.wait_for_selector('.stMainBlockContainer', timeout=15000)
```

### Streamlit cold-start pattern
```python
from playwright.sync_api import Page

def wait_streamlit_ready(page: Page, url: str, anchor: str, timeout: int = 30000):
    page.goto(url, wait_until="domcontentloaded")
    page.wait_for_selector('.stApp', timeout=timeout)
    page.wait_for_selector(anchor, timeout=timeout)
    return page

# Usage
wait_streamlit_ready(
    page,
    url="https://priav5-production.up.railway.app",
    anchor='[data-testid="stToolbar"]',
    timeout=40000
)
```

### Streamlit after-widget-interaction
```python
def streamlit_interact_and_wait(page, selector, action_fn):
    page.wait_for_selector(selector, state="attached", timeout=10000)
    action_fn(page)
    try:
        page.wait_for_selector(selector, state="hidden", timeout=5000)
    except Exception:
        pass
    page.wait_for_selector(selector, state="visible", timeout=15000)

# Example
streamlit_interact_and_wait(
    page,
    selector='[data-testid="stSelectbox"]',
    action_fn=lambda p: p.click('[data-testid="stSelectbox"]')
)
```

## Rule 4 — Adaptive element finding

```python
from playwright.sync_api import Page

def find_adaptive(page: Page, label_text: str, tag: str = "*"):
    """Find an element by its visible text content, regardless of DOM path."""
    return page.query_selector(f'{tag}:has-text("{label_text}")')

# BAD — hardcoded path
page.query_selector('div:nth-child(3) > div:nth-child(1) > span')

# GOOD — content-anchored
span = find_adaptive(page, "Total Students: 42")
```

## Rule 5 — Detect DOM mutation rather than waiting blindly

```python
from playwright.sync_api import Page, expect

def wait_for_dom_stable(page: Page, selector: str, stability_ms: int = 1000):
    import time
    last_count = 0
    stable_start = None

    while True:
        elements = page.query_selector_all(selector)
        current_count = len(elements)

        if current_count == last_count:
            if stable_start is None:
                stable_start = time.time()
            elif (time.time() - stable_start) * 1000 >= stability_ms:
                return elements
        else:
            stable_start = None

        last_count = current_count
        time.sleep(0.25)

        if (time.time() - stable_start or time.time()) > 30:
            break

    return page.query_selector_all(selector)
```

## Rule 6 — Railway-specific cold start

Railway's ephemeral filesystem means the container restarts on every deploy. Cold start times:
- Streamlit on Railway: **20-45 seconds**
- FastAPI on Railway: **5-15 seconds**

```python
COLD_START_TIMEOUT = 45_000  # ms for Streamlit on Railway

def wait_railway_ready(page: Page, url: str) -> bool:
    import time
    start = time.time()

    while time.time() - start < 60:
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=10000)
            page.wait_for_selector('.stApp', timeout=COLD_START_TIMEOUT)
            return True
        except Exception:
            time.sleep(5)

    return False
```
