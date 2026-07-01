---
name: js-modern-patterns
description: "Modern ES2022+ and TypeScript patterns for cleaner, more efficient code. Covers top-level await, optional chaining, nullish coalescing, modern array methods (at, findLast, toSorted), Object.hasOwn, Error.cause, structuredClone, and idiomatic patterns for the user's stack (Next.js 14, React 19, Vite, Express, Node.js, TypeScript). Use when writing or reviewing JavaScript/TypeScript code with modern features. Triggers: javascript, typescript, es2022, modern js, ts patterns, react patterns, next.js, express."
triggers:
  - "js-modern-patterns"
  - "js modern patterns"
  - "when to use js modern patterns"
  - "how to js modern patterns"
  - "js modern patterns examples"
  - "js modern patterns pattern"
applies_to:
  - "main-coordinator"
---


# JS/TS Modern Patterns — ES2022+ Idioms

## When to use this

Load this skill when:
- Writing modern JavaScript (ES2022+) or TypeScript code
- Working with Next.js 14, React 19, Vite, or Express
- Reviewing JS/TS code for idiomatic patterns
- Migrating older JS code (var, function(){}, etc.) to modern syntax
- Building full-stack apps with Node.js + frontend framework

Do NOT use this skill when:
- Pre-ES2020 code (different patterns apply)
- Browser-specific quirks (use `webapp-testing` skill)
- Performance-critical JS (use `performance-optimization` skill)
- Security-focused code (use `secure-coding` skill)

---

## Core patterns

### 1. Declarations

**`const` by default, `let` only when reassignment needed**:

```typescript
// GOOD
const API_URL = "https://api.example.com";
const users = await fetchUsers();
let counter = 0;
counter += 1;

// AVOID
var API_URL = "...";  // var is function-scoped, hoisted — bugs waiting to happen
let users;  // declared but never reassigned — should be const
```

**Arrow functions for callbacks, regular for methods**:

```typescript
// GOOD — arrow for callbacks (lexical `this`)
const doubled = numbers.map((n) => n * 2);

// GOOD — regular function for methods (own `this`)
class UserService {
  getUser(id: number): User {
    return this.db.find(id);
  }
}

// AVOID — arrow for methods (wrong `this`)
class UserService {
  getUser = (id: number): User => {
    return this.db.find(id);  // `this` is the instance, but method is detached
  };
}
```

### 2. Destructuring with rename + default

```typescript
// GOOD
function processUser({ id, name, email = "unknown" }: User) {
  return { userId: id, displayName: name, contact: email };
}

// Rename for clarity
const { id: userId, name: userName } = user;
```

### 3. Optional chaining + nullish coalescing

**`?.` for safe access, `??` for null/undefined fallback**:

```typescript
// GOOD
const city = user?.address?.city ?? "Unknown";
const count = data?.items?.length ?? 0;

// AVOID — long && chains
const city = user && user.address && user.address.city
  ? user.address.city
  : "Unknown";
```

**`??=` for lazy init**:

```typescript
// GOOD
let cached = cache.get(key);
cached ??= computeExpensive(key);
cache.set(key, cached);

// AVOID
if (!cached) {
  cached = computeExpensive(key);
  cache.set(key, cached);
}
```

### 4. Modern array methods

**`at()` for negative indices, `findLast()` / `findLastIndex()`**:

```typescript
const items = ["a", "b", "c", "d"];
items.at(-1);          // "d" (vs items[items.length - 1])
items.at(0);           // "a"

const nums = [1, 2, 3, 4, 5];
const lastEven = nums.findLast((n) => n % 2 === 0);  // 4
const lastEvenIdx = nums.findLastIndex((n) => n % 2 === 0);  // 3
```

**Non-mutating `toReversed` / `toSorted` / `toSpliced`** (ES2023):

```typescript
// GOOD — non-mutating (immutable)
const reversed = items.toReversed();
const sorted = items.toSorted((a, b) => a - b);
const withoutFirst = items.toSpliced(0, 1);

// AVOID — mutating (breaks React/Redux patterns)
const reversed = items.reverse();  // mutates items!
```

### 5. `Object.hasOwn` over `hasOwnProperty`

```typescript
// GOOD — works even with prototype-less objects
if (Object.hasOwn(obj, "key")) {
  // ...
}

// AVOID — fails if obj has null prototype
if (obj.hasOwnProperty("key")) {
  // ...
}
```

### 6. Top-level await (ES2022)

In ESM modules (Next.js, Vite, modern Node):

```typescript
// GOOD — works in ESM modules
const config = await loadConfig();
const db = await connectDb(config.dbUrl);

export { config, db };
```

```javascript
// CommonJS (older Node) — wrap in async IIFE
async function main() {
  const config = await loadConfig();
  // ...
}
main();
```

### 7. `Error.cause` for error chains (ES2022)

```typescript
// GOOD
try {
  return await fetchUserData(userId);
} catch (err) {
  throw new Error(`Failed to load user ${userId}`, { cause: err });
}

// Catch side
try {
  await loadUser(id);
} catch (err) {
  if (err.cause instanceof NetworkError) {
    log.warn("Network issue", err.cause);
  }
}
```

### 8. `structuredClone` for deep copy

```typescript
// GOOD — deep clone any cloneable object
const original = { user: { name: "Alice", prefs: { theme: "dark" } } };
const copy = structuredClone(original);
copy.user.prefs.theme = "light";
console.log(original.user.prefs.theme);  // "dark" — original untouched

// AVOID — JSON round-trip loses types, dates, etc.
const copy = JSON.parse(JSON.stringify(original));
```

### 9. Logical assignment operators

```typescript
// GOOD
a ||= b;  // a = a || b
a &&= b;  // a = a && b
a ??= b;  // a = a ?? b (only if null/undefined)

// AVOID — verbose
a = a || b;
```

### 10. Numeric separators

```typescript
// GOOD — readable large numbers
const bytesInGigabyte = 1_073_741_824;
const apiTimeoutMs = 30_000;

// AVOID — hard to count zeros
const bytesInGigabyte = 1073741824;
```

---

## TypeScript-specific patterns

### 1. Discriminated unions over enums

```typescript
// GOOD — type-safe, exhaustive checking
type Status = "pending" | "success" | "error";
type Result<T> =
  | { status: "pending" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error };

function handle<T>(result: Result<T>) {
  switch (result.status) {
    case "pending": return;
    case "success": console.log(result.data); break;
    case "error": throw result.error;
  }
}

// AVOID — runtime overhead, no exhaustiveness
enum Status { Pending, Success, Error }
```

### 2. `satisfies` for type checking without widening

```typescript
// GOOD — type-checked but keeps literal types
const routes = {
  home: { path: "/", auth: false },
  admin: { path: "/admin", auth: true },
} satisfies Record<string, Route>;

// routes.home.auth is `false` (literal), not `boolean`
type Route = { path: string; auth: boolean };

// AVOID — widens to Route (loses literal)
const routes: Record<string, Route> = { ... };
```

### 3. `unknown` over `any`, `never` for exhaustiveness

```typescript
// GOOD
function process(data: unknown) {
  if (typeof data === "string") {
    return data.toUpperCase();
  }
  if (Array.isArray(data)) {
    return data.map(process);
  }
  throw new Error("Unsupported type");
}

// Exhaustiveness check
function assertNever(x: never): never {
  throw new Error(`Unhandled: ${JSON.stringify(x)}`);
}
```

### 4. Branded types for domain primitives

```typescript
type UserId = string & { readonly __brand: "UserId" };
type Email = string & { readonly __brand: "Email" };

function createUser(id: UserId, email: Email): User {
  // Type system prevents passing raw strings
}
```

---

## React 19 + Next.js 14 patterns

### 1. Server Components by default

```typescript
// app/users/page.tsx — server component by default
export default async function UsersPage() {
  const users = await db.getUsers();  // direct DB access, no useEffect
  return <UserList users={users} />;
}
```

### 2. `'use client'` only when needed

```typescript
"use client";  // only for components with state, effects, or event handlers

import { useState } from "react";

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### 3. Server Actions for mutations

```typescript
// app/actions.ts
"use server";

export async function createUser(formData: FormData) {
  const email = formData.get("email") as string;
  await db.createUser({ email });
  revalidatePath("/users");
}
```

### 4. `use()` hook for promises/context (React 19)

```typescript
// Read promise in client component
function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);  // suspends until resolved
  return <div>{user.name}</div>;
}
```

---

## What NOT to include (per research)

These are auto-detected by the agent — don't restate:

- `var` is bad (everyone knows)
- `===` over `==` (universal)
- Async/await basics (model knows)
- React component basics
- npm vs yarn vs pnpm (project choice)

---

## Cross-references

- `skills/api-patterns` — REST API design with Express/Next.js
- `skills/fullstack-dev` — Full-stack patterns
- `skills/secure-coding` — OWASP-aware JS/TS patterns
- `rules/common.md` — Cross-cutting rules (15-call budget, etc.)
- `agents/code-reviewer.md` — reviews JS/TS code

---

## Version notes

- **ES2022**: top-level await, `Error.cause`, `Object.hasOwn`, `.at()`, class fields
- **ES2023**: `toReversed` / `toSorted` / `toSpliced`, `findLast` / `findLastIndex`
- **ES2024**: `Object.groupBy`, `Promise.withResolvers`, `ArrayBuffer.transfer`
- **React 19**: `use()` hook, server actions, async transitions
- **Next.js 14**: App Router stable, server actions GA, partial prerendering

User's stack: Next.js 14, React 19, Vite, Express, Node.js. Use these patterns when writing/reviewing code in those projects.