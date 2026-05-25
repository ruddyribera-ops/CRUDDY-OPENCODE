# Design System — [Project Name]

<!-- 
  Separate from AGENTS.md. The agent loads this only when working on UI.
  ITERATION RULE: If you discover a new design decision during this session, 
  add it to this file. This file improves with every UI session.
-->

## 1. Visual Framework (Pick One)

<!-- Delete sections that don't apply to your project -->

### Streamlit
- Theme set via `.streamlit/config.toml` or `st.set_page_config()`
- Primary color: ________
- Background color: ________
- Secondary background: ________
- Text color: ________
- Font: ________ (default: sans-serif)
- Base spacing unit: ________ (Streamlit default: 1rem)

### React / Next.js
- Styling: [Tailwind / CSS Modules / styled-components / shadcn/ui]
- Design tokens file: `________`
- Primary color (OKLCH preferido): ________
- Font stack: ________ (banned: Inter, Geist)

### HTML + CSS
- CSS custom properties in: `________`
- Reset/normalize: [yes/no]
- Responsive breakpoints: ________

---

## 2. Color System

### Banned Colors (AI Slop Giveaways)
- [ ] Purple (#7c3aed / purple-600) as primary
- [ ] White background + purple CTA combo
- [ ] Default Streamlit blue (#0068c9 / #29b5e8)
- [ ] Green success / red danger without custom shade

### Approved Palette
```
Primary:    ________
Secondary:  ________
Accent:     ________
Background: ________
Surface:    ________
Text:       ________
Muted:      ________
Success:    ________
Error:      ________
```

### Contrast Rules
- Body text vs background: minimum __________:1 ratio
- CTA buttons: always highest contrast on page
- Non-interactive elements: lower contrast than interactive

---

## 3. Typography

### Banned Fonts (every agent defaults to these)
- [ ] Inter
- [ ] Geist
- [ ] Roboto (unless it's the brand font)

### Approved Fonts
| Role | Font | Weight | Size |
|------|------|--------|------|
| Heading 1 | ________ | ________ | ________ |
| Heading 2 | ________ | ________ | ________ |
| Body | ________ | ________ | ________ |
| Small / Caption | ________ | ________ | ________ |

---

## 4. Layout Rules

### Global
- Symmetry: [symmetric / asymmetric] — symmetric for professional, asymmetric for artistic
- Negative space: [generous / compact]
- Max content width: ________

### Anti-Patterns (DO NOT USE)
- [ ] Centered CTA with nothing around it
- [ ] Glassmorphism / frosted glass effects
- [ ] Gradient text on gradient backgrounds
- [ ] Lucid / Heroicons defaults
- [ ] Cards with excessive shadow (box-shadow > 0 4px 12px)
- [ ] Purple-to-blue gradients

### Spacing
- Base unit: ________
- Section padding: ________
- Card padding: ________
- Button padding: ________
- Gap between elements: ________

---

## 5. Component Rules

### Consistent Across All Pages
- Buttons: [filled / outlined / text-only] with radius ________
- Inputs: border ________, focus ring ________, radius ________
- Cards: background ________, border ________, shadow ________
- Navigation: [sidebar / top bar / bottom tabs], background ________
- Modals: overlay ________, content background ________

### Anti-Patterns
- [ ] Buttons with different styles on different pages
- [ ] Spacing between components varies wildly
- [ ] Mixed border radii (rounded here, square there)
- [ ] Inconsistent loading states (spinner on page A, skeleton on page B)

---

## 6. Streamlit-Specific Rules (delete if not Streamlit)

### Do
- Use `st.set_page_config()` at the top of every page
- Wrap heavy operations in `st.spinner()` or `st.status()`
- Use `st.columns()` for layout, not custom HTML
- Match `st.button()`, `st.text_input()`, `st.selectbox()` style

### Don't
- Mix `st.write()` with proper Streamlit components
- Leave default theme (always override in `.streamlit/config.toml`)
- Use `st.markdown()` for layout when `st.columns()` would work

---

## 7. Iteration Log (Agent Fills This)

<!-- The agent adds lines here when it discovers a design decision -->

| Date | Decision | Why |
|------|----------|-----|
| | | |
