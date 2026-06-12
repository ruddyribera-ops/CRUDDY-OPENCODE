# Designer Agent — Test Prompts

## Positive Tests (should route TO designer)

### Test 1: Design system with status types
**Prompt:** "Design a dashboard for a system health monitor with these 4 status types: healthy (green), warning (yellow), failing (red), unknown (gray). Use a dark theme."

**Expected:** Designer produces token spec (JSON with semantic color tokens), component inventory (status badge variants), and HTML/CSS deliverable showcasing the dashboard components.

**What to verify:**
- Token spec with semantic names for all 4 status colors
- No raw hex values in output
- Component inventory with variant matrix
- Dark theme tokens defined

---

### Test 2: Component library expansion
**Prompt:** "We need a button component that supports 3 variants (primary, secondary, ghost) and 4 states (default, hover, active, disabled). Add it to our design system."

**Expected:** Designer adds to component inventory with full variant/state matrix, updates token spec with button-specific tokens, includes "when to use" / "when not to use" guidance.

**What to verify:**
- Variant matrix: 3 × 4 = 12 combinations documented
- Token references for all button colors
- Use-case guidance included

---

### Test 3: Brand token audit
**Prompt:** "Our startup just rebranded. We have these brand colors: primary #6366f1, secondary #a855f7, accent #f472b6. Define our design token system."

**Expected:** Designer produces a semantic token JSON that maps raw hex values to named tokens, defines type scale, spacing, and radius tokens, and explains the multi-brand architecture.

**What to verify:**
- All 3 brand colors mapped to semantic tokens
- Spacing scale defined (4px grid)
- Type scale defined
- Radius tokens defined

---

## Negative Tests (should route AWAY from designer)

### Test 4: Copywriting request (→ tech-writer)
**Prompt:** "Write me some marketing copy for a landing page that highlights our AI-powered analytics platform."

**Expected routing:** Route to `@tech-writer`. Designer should not attempt this.

**Why:** This is pure copywriting with no visual design component. No tokens, no components, no mockups.

---

### Test 5: Code implementation (→ code-builder)
**Prompt:** "Build a React component for a user profile card with avatar, name, bio, and follow button."

**Expected routing:** Route to `@code-builder`. Designer should not attempt implementation.

**Why:** This is a code implementation request. Designer produces specs, not implementation code.

---

### Test 6: Accessibility audit (→ code-analyzer)
**Prompt:** "Audit the checkout flow UI for accessibility issues."

**Expected routing:** Route to `@code-analyzer`. Designer should not attempt a technical accessibility audit.

**Why:** Accessibility auditing requires running tools against live code. Designer produces specs, not audits.

---

### Test 7: CSS bug fix (→ code-builder)
**Prompt:** "The spacing on our pricing table is broken on mobile. Fix the CSS."

**Expected routing:** Route to `@code-builder`. Designer should not fix CSS bugs.

**Why:** CSS bug fixing is implementation work, not design specification work.

---

## Edge Case Tests

### Test 8: Unclear scope
**Prompt:** "Make the homepage look better."

**Expected behavior:** Designer asks clarifying questions before proceeding:
- Who is the target audience?
- What brand guidelines apply?
- Is there an existing design system to extend?
- What does "better" mean — clearer hierarchy? More modern? Mobile-first?

**What to verify:** Designer does NOT produce output without scope clarification.

---

### Test 9: Multi-brand request
**Prompt:** "We serve 3 different customer segments with distinct brands. Design a token system that supports all three with a shared component library."

**Expected:** Designer produces a token architecture with base tokens, brand-level overrides, and a component inventory where components consume base tokens only (brand values come from theme layer).

**What to verify:**
- Base token layer defined
- Brand override layer defined
- Components consume base tokens, not brand tokens directly

---

### Test 10: Visual-only mockup rejection
**Prompt:** "Here's a Figma mockup screenshot. Build the HTML/CSS for it." (without providing token spec)

**Expected:** Designer flags that the request lacks token specs and component inventory. Designer offers to produce the token spec first, then the implementation-ready HTML/CSS.

**What to verify:** Designer does NOT produce raw HTML matching the mockup without token documentation.