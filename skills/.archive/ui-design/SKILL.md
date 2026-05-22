---
name: ui-design
description: UI/UX design patterns — typography, spacing, color, accessibility, and framework-specific design systems (Tailwind, shadcn/ui, Streamlit theming)
tags: [design, ui, ux, frontend, accessibility]
---

# UI Design Patterns

## When to Use
- Designing or reviewing UI layouts and component spacing
- Setting up design tokens (colors, typography, spacing)
- Applying accessibility (color contrast, focus states, labels)
- Using Tailwind, shadcn/ui, or Streamlit theming

## Do Not Use
- Android Material Design specifics (use android-native-dev)
- Document/print layout (use msoffice-tools)
- Brand identity or logo design

## TL;DR — Top 5 Rules (Always Apply)
1. **Spacing = multiples of 4 or 8** (use Tailwind defaults, never custom px)
2. **Max 6 text sizes, max 2 fonts, max 1 alignment per section** — hierarchy from size+weight+whitespace
3. **Semantic color tokens, never raw hex** — `--color-primary` not `#3b82f6`. Dark mode = 2-line change
4. **Body text contrast ≥ 4.5:1 (WCAG AA)** — minimum `#6b7280` on white
5. **Design empty/loading/error states FIRST** — skeleton > spinner, specific > generic

**Framework shortcuts:** React/TS → `shadcn/ui` (`npx shadcn@latest init`). Streamlit → `.streamlit/config.toml` theme.

## The 4/8 Spacing Grid
Every margin, padding, gap, size = multiple of 4px (or 8px for layout-scale): `4, 8, 12, 16, 24, 32, 48, 64`.
Tailwind: `p-1`=4px, `p-2`=8px, `p-4`=16px, `p-6`=24px, `p-8`=32px.

## Typography Scale
| Role | Size | Tailwind | Weight |
|------|------|----------|--------|
| Body | 16px | `text-base` | 400 |
| Small | 14px | `text-sm` | 400 |
| H3 | 20px | `text-xl` | 600 |
| H2 | 24px | `text-2xl` | 600 |
| H1 | 30-36px | `text-3xl`-`text-4xl` | 700 |

Line height: body 1.5-1.6, headings 1.2-1.3. Pick ONE body + ONE heading font. System font stacks are fastest.

## Semantic Color Tokens
```css
:root {
  --color-bg: #ffffff; --color-surface: #f9fafb; --color-text: #111827;
  --color-text-muted: #6b7280; --color-border: #e5e7eb;
  --color-primary: #3b82f6; --color-primary-hover: #2563eb;
  --color-success: #10b981; --color-warning: #f59e0b; --color-danger: #ef4444;
}
[data-theme="dark"] { --color-bg: #0f172a; --color-surface: #1e293b; --color-text: #f1f5f9; }
```

## Contrast Ratios (WCAG AA)
- Body text: **4.5:1** — Large text: **3:1** — UI controls: **3:1**
- Check: webaim.org/resources/contrastchecker or browser devtools
- Light-gray on white (`#ccc` on `#fff` = 1.6:1 — FAILS). Minimum `#6b7280`.

## Component Libraries
- **React/TS:** `npx shadcn@latest init` then `npx shadcn@latest add button dialog input select`
- **Streamlit:** theme in `.streamlit/config.toml`, use `st.columns()`, `st.container(border=True)`, `st.tabs()`, `st.form()`

## Layout Principles
- Max-width container: `max-width: 72rem; margin: 0 auto; padding: 0 1.5rem;`
- Text line length: ~65-75 characters
- Hierarchy via size + weight + spacing (color is last tool)
- Left alignment default. Centered text = headlines only.

## Empty States, Loading, Errors
- **Empty:** actionable ("No posts yet. Create your first →")
- **Loading:** skeleton > spinner (perceived speed)
- **Error:** specific + recoverable ("Couldn't save — check your connection and try again")

## Anti-Patterns
- Custom everything → use battle-tested primitives
- Color as only signal → add icon + text
- Hover-only discovery → mobile has no hover
- Mixing font sizes in same paragraph → use weight/italic instead
- Too many typefaces → max 2 fonts

## Quick Audit Checklist
- [ ] Spacing = multiple of 4 or 8
- [ ] ≤ 6 text sizes
- [ ] Semantic color tokens, not raw hex
- [ ] Body contrast ≥ 4.5:1
- [ ] Max-width on content
- [ ] Loading, empty, error states designed
- [ ] Focus states visible (tab through UI)
- [ ] Works at 320px wide
- [ ] No info conveyed by color alone

## Framework-Specific Notes
- **Tailwind:** Default scale only, `darkMode: 'class'`, use utilities not `@apply`
- **shadcn/ui:** Install only components used, customize via Tailwind classes
- **Streamlit:** `config.toml` theme, `st.form()` for batch submit, `st.cache_data` to avoid re-render

## Ecosystem
→ See `references/ecosystem.md` for: color tools, typography, icons, design systems, stock resources, design tools, accessibility tools

## Verification
- [ ] Spacing audit passes (all values in 4/8 increments)
- [ ] Color contrast ≥ 4.5:1 for body text (WCAG AA)
- [ ] Semantic tokens used everywhere (no raw hex except brand colors)
- [ ] Loading/empty/error states exist for every component
- [ ] Focus rings visible on all interactive elements
- [ ] All reference links resolve
