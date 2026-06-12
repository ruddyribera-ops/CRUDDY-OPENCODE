# Sprint — test01 (Tip Calculator)

**Started:** 2026-06-08
**Appetite:** 1 hour (trivial, single-file)
**Hill position:** climbing (approach clear, single task)

## Sprint Goal

Ship a single self-contained `index.html` that calculates tip + total in real time, working on mobile and desktop.

## Task

1. **[PICKED] Build the tip calculator HTML file** — code-builder — 0.5 day (target: < 1 hour)
   - **Deliverable:** `index.html` at project root, fully self-contained (inline CSS + JS, no external deps)
   - **Inputs:** Bill amount (number) + tip selector (15% / 18% / 20% preset buttons + custom % input)
   - **Output:** Live-updated tip amount and grand total
   - **Acceptance criteria:**
     - All three preset buttons work and highlight when active
     - Custom tip % accepts decimals (e.g. 22.5)
     - Total updates on every input change (no submit button)
     - Responsive: usable on a phone (touch targets ≥ 44px) and desktop
     - No console errors in Chrome DevTools
   - **Out of scope:** bill splitting, dark mode, persistence, backend

2. **[QUEUED] Verify in browser + Loom walkthrough** — Delivery — 0.25 hour
   - Open the file in Chrome via auto-browser
   - Click through all presets + custom
   - Record 30-60s walkthrough (mobile + desktop viewport)
   - Confirm no console errors, no broken layout

## Today's focus

- code-builder builds `index.html`

## Blockers

- (none)

## Risks

- Low risk. Only one: typo in tip % math. Mitigation: code-builder tests with bill=$48.50, 18% → tip=$8.73, total=$57.23 before handing off.

## Tomorrow's focus

- (sprint ends — Delivery verifies + demo to client)

## Definition of Done

- `index.html` exists at `C:\Users\Windows\.config\opencode\memory\factory\projects\test01\index.html`
- code-builder ran a manual smoke test with one preset + one custom value
- Delivery Engineer opened it in browser, no errors, recorded walkthrough
- AM gets the file + walkthrough to send to client
