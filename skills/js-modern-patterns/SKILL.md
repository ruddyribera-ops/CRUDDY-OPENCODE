---
name: js-modern-patterns
description: Modern JavaScript/TypeScript patterns — React 19, hooks, async patterns, ES2024+, type-safe idioms. Covers component architecture, state management, error boundaries, and performance patterns.
triggers: typescript, react, javascript, frontend, async, hooks, tsx, jsx, modern-js
auto_load: code-builder
---

# Modern JS/TS Patterns

## Key Principles
- **TypeScript strict mode always** — no `any`, no `ts-ignore`
- **React 19 patterns**: use() hook, Server Components, Actions
- **Async**: async/await with proper error boundaries, never bare promises

## React 19 Specifics
- `use(Promise)` instead of `useEffect` + `fetch` for data fetching
- `useActionState` for form actions (replaces `useFormState`)
- Server Components by default, client components only when interactivity needed

## Error Handling
- Error boundaries at route segment level
- Never swallow errors — always log + surface to user
- `try/catch` with typed errors, not `catch (e: any)`

## Performance
- Lazy load routes with `React.lazy` + `Suspense`
- Memoize with `useMemo`/`useCallback` only when profiler shows re-render cost
- Code split at route level, not component level
