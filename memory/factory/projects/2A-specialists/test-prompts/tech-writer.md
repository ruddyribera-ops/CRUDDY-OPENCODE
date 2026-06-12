# Test prompt — tech-writer

**Agent under test:** `tech-writer`
**Manifest:** `agents/tech-writer.md` (markdown-only, no YAML for 2A lean spec)
**Tested by:** delivery-engineer (T8)
**Date:** 2026-06-08
**Reference:** `memory/factory/projects/2A-specialists/reference/agent-template.md`

---

## Test 1 (positive): Document a new API endpoint

**Goal:** Verify the tech-writer can produce a GEO-optimized, Diataxis-aligned reference page for a new endpoint using the locked page template.

**Input:**
```
Document the new POST /api/plants endpoint following the GEO template.
```

**Expected output shape:**
```markdown
# Create a plant

> TL;DR (≤50 words): POST /api/plants creates a new plant record. Auth required. Returns 201 with the plant object, or 400/401/409 on validation/auth/duplicate. See `src/routes/plants.py:42`.

## Problem
You have a plant you want to track. Send its name, species, and optional location.

## API
| Param | Type | Required | Notes |
|-------|------|----------|-------|
| name | string | yes | 1-80 chars |
| species | string | yes | from `species` enum |
| location | string | no | free text, ≤120 chars |

## Example
\`\`\`bash
curl -X POST https://api.example.com/plants \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Basil","species":"herb"}'
\`\`\`
→ `201 {"id":"p_123","name":"Basil","species":"herb"}`

## Failure modes
| Symptom | Cause | Fix |
|---------|-------|-----|
| 400 | missing/invalid field | check `errors[]` in body |
| 401 | bad/missing token | refresh token, retry |
| 409 | duplicate name for user | pick a unique name |

## See also
- `GET /api/plants` — list your plants
- `DELETE /api/plants/{id}` — remove a plant
```

**Pass criteria:**
- [ ] Output matches the GEO page template (TL;DR → Problem → API → Example → Failure modes → See also)
- [ ] TL;DR is ≤50 words
- [ ] Worked example is present and runnable (curl + JSON)
- [ ] Failure modes table populated (≥3 rows)
- [ ] Cites source file with line number (`src/routes/plants.py:42`)
- [ ] No marketing language ("seamless", "leverage", "robust")
- [ ] Last-verified stamp present
- [ ] Names GEO + Diataxis explicitly in the response

**Actual output (paste from opencode agent run):**
```
<paste here>
```

**Result:** PASS / FAIL / PARTIAL
**Notes:** <anything the test revealed>

---

## Test 2 (negative): Out-of-scope request — implementation

**Goal:** Verify the tech-writer recognizes an implementation request and routes it to `@code-builder` rather than producing docs for a non-existent feature.

**Input:**
```
Build the new POST /api/plants endpoint.
```

**Expected output:**
The tech-writer MUST:
1. Refuse to build (out of scope — docs only, not implementation)
2. Route to `@code-builder` explicitly
3. Offer to document the endpoint ONCE it exists

**Pass criteria:**
- [ ] Output does NOT contain implementation code
- [ ] Output does NOT silently start building
- [ ] Output names `@code-builder` as the correct agent
- [ ] Output offers a docs handoff once the endpoint is built
- [ ] Tone is terse, not lecturing

**Sample expected response shape:**
```
This is a build request, not a docs request. Routing to @code-builder.

Once the endpoint is built and merged, send it back to me with the source
file path and I'll produce a GEO-aligned reference page following the
locked page template.
```

**Actual output (paste from opencode agent run):**
```
<paste here>
```

**Result:** PASS / FAIL
**Notes:** <anything the test revealed>

---

## Notes for delivery-engineer (T8)

- Both tests must pass before T8 marks tech-writer shippable.
- If Test 1 fails the GEO template check, escalate to `@code-reviewer`.
- If Test 2 fails (agent starts building), the routing table in AGENTS.md is wrong — fix triggers and re-test.
