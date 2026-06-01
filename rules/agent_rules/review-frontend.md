---
description: Frontend reviewer — checks component size, accessibility, performance
condition: useState\(\s*\[\s*\]\s*\)|useEffect\(\s*\(\s*\)\s*=>\s*\{\s*\}\s*,\s*\[\s*\]\)|memo\(\s*\(\s*\)\s*=>\s*\{
scope: "tool:edit(**/*.{tsx,jsx,js,ts,css,scss})"
severity: warning
triggered_by: frontend concern
---

# Frontend Review (Auto-Reviewer Persona)

Checks every change for frontend best practices. Triggered on every push.

## What it catches

| Pattern | Why |
|---------|-----|
| Component > 250 lines | Hard to test, hard to review, hard to maintain |
| Missing `aria-` or `role=` | Accessibility gap |
| `useEffect` without cleanup | Memory leaks |
| CSS class not in design system | Visual inconsistency |
| Inline styles | Bypasses design system |
| No loading/error/empty states | Brittle UX |

## Fix

- Large components: split into smaller, testable units
- Accessibility: add `aria-label`, `role`, keyboard navigation
- useEffect: always return cleanup function
- Styles: use design tokens from `.opencode/design.md`
- States: every data-fetching component must handle loading, error, empty
