---
name: js-modern-patterns
description: Modern ES2022+ and TypeScript patterns for cleaner, more efficient code
tags: [javascript, typescript, frontend, patterns]
tags: [javascript, typescript, es2022, modern-js, web, nodejs]
---

## When to Use
- Writing modern JavaScript/TypeScript with ES2022+ features
- Using nullish coalescing, optional chaining, and other modern operators
- Implementing async/await, promises, and error handling patterns
- Structuring TypeScript interfaces and types for maintainability
- Adopting functional and immutable coding patterns

## Do Not Use
- Frontend framework-specific patterns (use frontend-dev or react-native-dev)
- Backend Node.js framework setup (use fullstack-dev)
- CSS or styling patterns (use ui-design)
- Build tool configuration (Vite, webpack, etc.)

# JavaScript/TypeScript Modern Patterns

## Core Patterns

### Nullish Coalescing & Optional Chaining
```typescript
const name = user.name ?? 'Anonymous';   // only null/undefined
const street = user?.address?.street ?? 'Unknown';
const city = user?.address?.city ?? 'Unknown';
```

### TypeScript: `interface` over `type` for Objects
```typescript
interface User { id: string; name: string; email: string; }
interface Admin extends User { permissions: string[]; }
```
`interface` allows declaration merging, extends, and gives better error messages.

### Discriminated Unions for State
```typescript
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

### `satisfies` Operator (TS 4.9+)
```typescript
const config = { port: 3000, host: 'localhost' } satisfies Config;
// Validates shape WITHOUT widening type
```

### Async Patterns
```typescript
// Parallel
const [users, posts] = await Promise.all([fetch('/api/users'), fetch('/api/posts')]);
// Settled (handle partial failures)
const results = await Promise.allSettled([fetch('/api/users'), fetch('/api/posts')]);
```

### Array & Immutability
- Transform: `users.reduce((acc, u) => { acc[u.id] = u; return acc; }, {} as Record<string, User>)`
- Update: `{ ...user, name: 'New Name' }`
- Remove: `items.filter((_, i) => i !== index)`
- Replace: `items.map((item, i) => i === index ? { ...item, ...updates } : item)`

### Error Handling
```typescript
type Result<T, E = Error> = { success: true; data: T } | { success: false; error: E };
```

### Modules: Named Exports Preferred
```typescript
export function helper() { ... }  // ✅ tree-shakeable
export default function main() { ... }  // ❌ avoid
```

## Patterns by Category
→ See `references/ecosystem.md` for full library catalog (functional, debugging, testing, build tools, CLI, streams, dates, parsing, compression)

## See Also
- [awesome-nodejs](https://github.com/sindresorhus/awesome-nodejs) — Curated Node.js resources
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) — Official TS docs
- [ES features](https://github.com/tc39/proposals) — TC39 proposals
- [Can I Use](https://caniuse.com) — Browser compatibility

## Verification
- [ ] TypeScript compiles with `strict: true` (no implicit any)
- [ ] No `any` types used — proper interfaces or type aliases
- [ ] Async functions use `Promise.allSettled` where partial failure is acceptable
- [ ] Objects use discriminated unions for state management
- [ ] All reference links resolve
