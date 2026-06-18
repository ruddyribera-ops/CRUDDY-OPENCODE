---
description: No TypeScript any type escape
condition: : any\b|as any\b
scope: "tool:edit(**/*.{ts,tsx})"
severity: error
triggered_by: any type escape
---

# No any Type Escapes

Never use `any` as a type shortcut. Use `unknown` or define the actual type.

## Fix
```typescript
// WRONG: const x = response as any;
// RIGHT: const x = response as ApiResponse;
```
