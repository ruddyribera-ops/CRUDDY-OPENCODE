---
name: ui-design
description: UI/UX design patterns — typography, spacing, color, accessibility, framework-specific design systems (Tailwind, shadcn/ui, Streamlit). Use when designing or reviewing user interfaces, choosing design tokens, or auditing visual quality. Triggers: UI design, UX, design system, typography, color palette, spacing, accessibility, Tailwind, shadcn.
---

# UI Design Skill

## When to Use

Use this skill when you need to:
- Design or review user interfaces
- Choose design tokens (colors, typography, spacing)
- Audit visual quality and accessibility
- Work with Tailwind, shadcn/ui, or Streamlit theming
- Create design systems or component libraries

## Core Principles

1. **Typography hierarchy** — Clear size and weight distinctions guide the eye
2. **Color contrast** — WCAG compliance is non-negotiable for accessibility
3. **Spacing scale** — Consistent 4px/8px grid creates visual rhythm
4. **Accessibility first** — Keyboard navigation and focus states are mandatory
5. **Framework follows function** — Choose tools that match the use case

## Typography

### Hierarchy Rules

| Level | Size | Weight | Use Case |
|-------|------|--------|----------|
| H1 | 2-3rem | Bold (700) | Page titles |
| H2 | 1.5-2rem | Semibold (600) | Section headers |
| H3 | 1.25rem | Semibold (600) | Subsection headers |
| Body | 1rem | Regular (400) | Default text |
| Caption | 0.875rem | Regular (400) | Secondary text |
| Small | 0.75rem | Regular (400) | Fine print |

### Font Selection

- **Sans-serif** for UI (better screen rendering): Inter, system-ui, -apple-system
- **Serif** for long-form reading: Georgia, Merriweather
- **Monospace** for code/data: JetBrains Mono, Fira Code

```css
/* Good: System font stack */
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }

/* Avoid: Web font with fallbacks */
body { font-family: 'Custom Font', 'Some Other Font', sans-serif; }
```

## Color Systems

### Design Token Structure

```css
:root {
  /* Primary palette */
  --color-primary-50: #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a8a;
  
  /* Semantic colors */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  
  /* Neutral scale */
  --color-gray-100: #f3f4f6;
  --color-gray-900: #111827;
}
```

### WCAG Contrast Requirements

| Level | Normal Text | Large Text |
|-------|-------------|------------|
| AA | 4.5:1 | 3:1 |
| AAA | 7:1 | 4.5:1 |

Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) to verify.

### Color Tool Recommendations

- **coolors.co** — Palette generation
- **colorhunt.co** — Curated palettes
- **material.io/resources/color** — Material Design colors
- **chroma-js** — programmatic color manipulation

## Spacing Scale

### 4px/8px Grid System

```css
/* Spacing scale (4px base) */
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
```

### Component Spacing

- **Padding** — Internal spacing within components (8-16px typically)
- **Margin** — External spacing between components (16-32px typically)
- **Gap** — Grid/flex gap for consistent item spacing

## Accessibility

### Keyboard Navigation

Every interactive element must be keyboard-accessible:

```css
/* Focus states — NEVER remove, only style */
:focus-visible {
  outline: 2px solid var(--color-primary-500);
  outline-offset: 2px;
}

/* Skip link for screen readers */
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: var(--color-primary-500);
  color: white;
  padding: 8px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
```

### ARIA Patterns

```html
<!-- Button -->
<button aria-label="Close dialog">×</button>

<!-- Loading state -->
<div aria-busy="true" aria-label="Loading results">
  <div aria-live="polite">Loading...</div>
</div>

<!-- Error message -->
<input aria-invalid="true" aria-describedby="email-error" />
<div id="email-error" role="alert">Please enter a valid email</div>
```

### Accessibility Tools

- **axe-core** — Automated testing
- **Lighthouse** — Performance + accessibility audit
- **WAVE** — Web accessibility evaluation
- **ally.js** — Accessibility utilities

## Framework-Specific Notes

### Tailwind CSS (Utility-First)

```html
<!-- Instead of semantic classes -->
<div class="flex items-center justify-between p-4 bg-white rounded-lg shadow">

<!-- Think in utilities, not components -->
<button class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
```

**Best practices:**
- Extract repeated patterns into components
- Use `group-*` for nested hover states
- Prefer `focus-visible` over `focus` for accessibility

### shadcn/ui (Component Library)

- Built on Radix UI primitives (accessible by default)
- Copy-and-paste components (not npm package)
- Customizable via Tailwind CSS variables
- Uses `cn()` utility for class merging

```tsx
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardContent } from '@/components/ui/card'
```

### Streamlit Theming

```python
# In .streamlit/config.toml
[theme]
primaryColor = "#3b82f6"
backgroundColor = "#ffffff"
secondaryBackgroundColor = "#f3f4f6"
textColor = "#111827"
font = "sans serif"
```

## Visual Design Tools

- **Figma** — Industry standard (free for small teams)
- **Penpot** — Open-source Figma alternative
- **Inkscape** — Vector graphics
- **Photopea** — Browser-based Photoshop
- **Spline** — 3D for web

## Anti-Patterns

- ❌ Ignoring color contrast (WCAG failure)
- ❌ Removing focus outlines for "cleaner" look
- ❌ Using px instead of rem for font sizes
- ❌ Inconsistent spacing (magic numbers everywhere)
- ❌ Designing without considering keyboard navigation
- ❌ Overly decorative fonts for body text

## Resources

See `references/ecosystem.md` for tools and resources organized by category:
- Color tools (coolors.co, colorhunt.co, etc.)
- Typography (Google Fonts, fontsource.org)
- Icon libraries (Lucide, Phosphor, Tabler)
- Design systems (shadcn/ui, Material Design 3, Radix UI)