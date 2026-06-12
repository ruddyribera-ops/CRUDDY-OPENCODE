---
description: Get the Friday demo ready. Triggers the Delivery Engineer to deploy to staging, record a 90-second auto-browser walkthrough, and hand URL + video to the PM. Optimized for the Friday 4pm demo to the client. Use when a feature is QA-signed-off and ready to demo.
usage: /factory-demo [project-id] [--feature <name>] [--no-record] [--early]
---

# /factory-demo — Get the Friday demo ready

Triggers the Delivery Engineer to take a feature that's QA-signed-off and make it demo-ready.

## What it does

1. **Verifies the feature is QA-signed-off** (checks `memory/factory/projects/<id>/qa-summary.md` for the sign-off)
2. **Triggers the Delivery Engineer** to:
   - Open staging in auto-browser
   - Smoke test the happy path
   - Record a 90-second walkthrough video via auto-browser
   - Save URL + video path to `memory/factory/projects/<id>/demos/`
3. **Hands the deliverable to the PM** for the Friday 4pm digest:
   - Live URL
   - 90-second walkthrough video path
   - Smoke test result
   - Final screenshot

## When to use

- **Friday morning** (after code-builder + QA are done) — prepare the Friday 4pm demo
- **Mid-sprint** with `--early` — record a progress demo, not the final delivery
- **Anytime** with `--no-record` — just deploy + smoke test, skip the video

## Flags

- `--feature <name>` — specific feature to demo (e.g., `--feature "watering-logic"`)
- `--no-record` — skip the video recording, just verify deploy + smoke test
- `--early` — this is a WIP demo, not the final delivery. Mark the video as `walkthrough-early-<date>.mp4`

## Output

```
Demo ready.

Project: plant-whisperer-2026-06
Feature: watering-logic
Staging URL: https://plant-whisperer.vercel.app
Walkthrough video: memory/factory/projects/plant-whisperer-2026-06/demos/walkthrough-2026-06-08.mp4
Smoke test: PASSED (navigate, login, add plant, view dashboard, logout all work)
Final screenshot: memory/factory/projects/plant-whisperer-2026-06/demos/final-screenshot-2026-06-08.png
Deploy log entry: appended

PM: hand to AM. AM posts at 4pm.
```

## Edge cases

- **QA hasn't signed off yet** → return `{ok: false, error: "QA sign-off required first"}` and dispatch to QA
- **No staging URL** → Delivery Engineer will deploy first, then record
- **First prod deploy** → Delivery Engineer ESCALATES via PM (24h client window)
- **Smoke test fails** → return `{ok: false, error: "smoke test failed"}` and dispatch to bug-fixer

## What the AM will do with this output

The AM gets the deliverable. At Friday 4pm, AM posts to the client:

```
> Your app is live at <URL>
> Here's a 90-second walkthrough: <video link>
> What's working: <bullets>
> What to test: <specific things>
> Reply "looks good" or "change X" — your call
```

That's the client experience. Loom-style video + clear ask. No jargon. No permission prompts.

## See also

- `/factory-kickoff` — start a new project
- `/factory-status` — get current status
- `/factory-blocker` — log a blocker
- `/factory-end` — sign off on delivery (Sprint 1F)