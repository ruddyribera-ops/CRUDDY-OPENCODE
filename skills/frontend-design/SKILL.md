---
name: frontend-design
description: Frontend design expertise — modern React patterns, CSS/Tailwind mastery, responsive design, accessibility (a11y), component architecture, animations, and performance optimization. Covers shadcn/ui, Tailwind, Framer Motion, and design system thinking.
triggers: [frontend, react, nextjs, vue, svelte, css, tailwind, scss, component, layout, design, ui, responsive, mobile-first, accessibility, a11y, animation, transition, shadcn, radix, headless-ui, framer-motion, design-system, storybook, figma, prototype, mockup, wireframe, landing, dashboard, form, modal, dropdown, navbar, sidebar, card, button, input, select, checkbox, radio, toggle, slider, tabs, accordion, dialog, tooltip, popover, toast, skeleton, spinner, loading, empty-state, error-state, dark-mode, theme, color, typography, spacing]
---

# Frontend Design Patterns

## Core Principles

1. **Mobile-first, always** — design for 320px first, then scale up with breakpoints
2. **Every state matters** — loading, empty, error, success, and edge cases for every component
3. **Accessibility is not optional** — keyboard navigation, screen reader support, contrast ratios
4. **Design is interactive** — micro-animations, transitions, and feedback make UI feel alive

---

## 1. Component Architecture

### Atomic Design Mental Model

```
atoms/       → Button, Input, Label, Icon (single responsibility)
molecules/   → SearchField, FormField, Card (combine 2+ atoms)
organisms/   → Header, Sidebar, ProductGrid (section-level)
templates/   → Page layout shells (structure without data)
pages/       → HomePage, ProductPage (data + template)
```

### Component Rules

```typescript
// ✅ GOOD: Single responsibility, composable
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'ghost' | 'danger';
  size: 'sm' | 'md' | 'lg';
  children: ReactNode;
  isLoading?: boolean;
  disabled?: boolean;
  onClick?: () => void;
}

// ❌ BAD: Too many responsibilities
interface CardProps {
  title: string;
  description: string;
  image: string;
  price: number;
  onAddToCart: () => void;
  onShare: () => void;
  onFavorite: () => void;
  // ... 20 more props
}
```

---

## 2. Tailwind CSS Mastery

### Design Token Approach

```css
/* tailwind.config.ts */
export default {
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a5f',
        },
        surface: {
          DEFAULT: '#ffffff',
          muted: '#f8fafc',
          border: '#e2e8f0',
        },
      },
      spacing: {
        'page': '1.5rem',    // 24px
        'section': '4rem',   // 64px
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Cabinet Grotesk', 'sans-serif'],
      },
    },
  },
};
```

### Layout Patterns

```tsx
// ✅ Page layout — consistent spacing
<div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
  <main className="space-y-12">
    <section>
      <h2 className="text-2xl font-semibold mb-6">Section Title</h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Cards */}
      </div>
    </section>
  </main>
</div>

// ✅ Responsive sidebar + content
<div className="flex flex-col lg:flex-row gap-8">
  <aside className="w-full lg:w-64 shrink-0">
    {/* Sidebar nav — stacks on mobile, side on desktop */}
  </aside>
  <main className="flex-1 min-w-0">
    {/* Main content */}
  </main>
</div>
```

### Responsive Breakpoints

```tsx
// Mobile-first: base styles = mobile, then override
<div className="
  grid-cols-1          /* Mobile: 1 column */
  sm:grid-cols-2       /* Tablet: 2 columns */
  lg:grid-cols-3       /* Desktop: 3 columns */
  xl:grid-cols-4       /* Wide: 4 columns */
  gap-4 sm:gap-6       /* Smaller gap on mobile */
  p-4 sm:p-6 lg:p-8    /* More padding on larger screens */
">
```

---

## 3. Every State Pattern

### Component States Cheatsheet

```tsx
function ProductCard({ product, isLoading, error }: ProductCardProps) {
  // 🟡 Loading
  if (isLoading) return <Skeleton className="h-64 w-full rounded-xl" />;

  // 🔴 Error
  if (error) return (
    <div className="flex flex-col items-center justify-center p-8 text-center">
      <AlertCircle className="h-8 w-8 text-red-500 mb-2" />
      <p className="text-sm text-red-600">Failed to load product</p>
      <button onClick={onRetry} className="mt-2 text-sm text-brand-600 hover:underline">
        Try again
      </button>
    </div>
  );

  // Empty
  if (!product) return null;

  // ✅ Success
  return (
    <div className="group relative rounded-xl border border-surface-border bg-white p-4 hover:shadow-lg transition-shadow">
      {/* Product content */}
    </div>
  );
}
```

### Empty State Guidelines

```
❌ NEVER show a blank page — always explain WHY it's empty
✅ Show: icon + message + call to action
✅ "No orders yet" → "Browse products" button
✅ "No search results" → "Try different keywords" + suggested searches
✅ "Empty cart" → "Start shopping" button with featured products
```

---

## 4. Accessibility (a11y) — Non-Negotiable

### Keyboard Navigation

```tsx
// ✅ All interactive elements are keyboard accessible
<button onClick={handleClick}>Action</button>  // Native button = keyboard accessible

// ❌ Don't use div as button without proper attributes
<div onClick={handleClick} role="button" tabIndex={0} onKeyDown={handleKeyPress}>Action</div>
// If you must: role="button" + tabIndex={0} + onKeyDown handling
```

### Focus Management

```tsx
// ✅ Modal focus trap
function Modal({ isOpen, onClose, children }) {
  const dialogRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isOpen) {
      dialogRef.current?.focus();  // Focus the modal when it opens
    }
  }, [isOpen]);

  // Close on Escape
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') onClose();
  };

  if (!isOpen) return null;
  return (
    <div role="dialog" aria-modal="true" aria-label="Dialog title"
         ref={dialogRef} tabIndex={-1} onKeyDown={handleKeyDown}
         className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Overlay + content */}
    </div>
  );
}
```

### Forms

```tsx
// ✅ Every input has a label
<div>
  <label htmlFor="email" className="block text-sm font-medium mb-1">
    Email address
  </label>
  <input
    id="email"
    type="email"
    aria-describedby="email-hint"
    aria-invalid={!!errors.email}
    className="w-full rounded-lg border px-3 py-2"
  />
  {errors.email && (
    <p id="email-hint" className="mt-1 text-sm text-red-600" role="alert">
      {errors.email}
    </p>
  )}
</div>

// ❌ No placeholder-only labels (they disappear when typing)
// ❌ No color-only error indicators (screen readers can't see them)
```

### Accessibility Checklist

- [ ] All images have meaningful `alt` text
- [ ] All interactive elements are keyboard-reachable (tabIndex)
- [ ] All forms have `<label>` elements connected via `htmlFor`/`id`
- [ ] Color contrast >= 4.5:1 (normal) / 3:1 (large)
- [ ] Error messages use `role="alert"`
- [ ] Modals/dialogs have `role="dialog"` + `aria-modal="true"` + `aria-label`
- [ ] Focus is trapped inside modals when open
- [ ] Page has skip-to-content link
- [ ] Heading hierarchy is logical (h1 → h2 → h3, no skips)

---

## 5. Dark Mode

```tsx
// ✅ Tailwind dark mode with class strategy
// tailwind.config.ts: darkMode: 'class'

// In layout:
const [isDark, setIsDark] = useState(() =>
  localStorage.getItem('theme') === 'dark' ||
  (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: dark)').matches)
);

useEffect(() => {
  document.documentElement.classList.toggle('dark', isDark);
  localStorage.setItem('theme', isDark ? 'dark' : 'light');
}, [isDark]);

// Usage:
// <div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
```

---

## 6. Micro-Interactions & Animations

### Purposeful Animation

```tsx
// ✅ Meaningful transitions (not decorative)
<div className="
  transition-all duration-200 ease-in-out
  hover:scale-[1.02] hover:shadow-md
  active:scale-[0.98]
">
  {/* Interactive card — subtle feedback */}
</div>

// ✅ Page transitions
<AnimatePresence mode="wait">
  <motion.div
    key={router.pathname}
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.2 }}
  >
    <Component {...pageProps} />
  </motion.div>
</AnimatePresence>

// ✅ Loading skeletons (morph from shimmer)
function Skeleton({ className }: { className: string }) {
  return (
    <div className={`animate-pulse bg-gray-200 dark:bg-gray-700 rounded ${className}`} />
  );
}
```

### Animation Rules

```
✅ Animate: page transitions, hover states, loading indicators, modal enter/exit
✅ Duration: 150-300ms (too fast = missed, too slow = feels sluggish)
✅ Easing: ease-in-out for enter/exit, ease-out for enter only
❌ DON'T: animate elements that appear in the first viewport (prefers-reduced-motion)
❌ DON'T: decorative animations that slow down interaction
❌ DON'T: rotation or spinning unless indicating progress
```

---

## 7. Performance

```tsx
// ✅ Lazy load below-fold content
import dynamic from 'next/dynamic';
const HeavyChart = dynamic(() => import('./HeavyChart'), { ssr: false });

// ✅ Image optimization
import Image from 'next/image';
<Image
  src={product.image}
  alt={product.name}
  width={400}
  height={300}
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
  loading="lazy"       // Offscreen images lazy load
  placeholder="blur"   // Show blur-up while loading
/>

// ✅ Debounce search input
const debouncedSearch = useMemo(
  () => debounce((value: string) => setQuery(value), 300),
  []
);
```

### Performance Checklist

- [ ] Images lazy-loaded below the fold
- [ ] Charts and heavy components code-split
- [ ] No layout shift (set explicit width/height on images)
- [ ] Debounced search/type inputs
- [ ] Virtual list for long scrollable lists (> 100 items)
- [ ] Bundle size monitored (keep < 200KB initial JS)
- [ ] No unnecessary re-renders (React.memo, useMemo, useCallback)

---

## 8. Anti-Patterns

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| "AI-slop" generic UI | Looks fake, no personality | Distinct spacing, colors, typography per brand |
| Everything centered | Unreadable on wide screens | Limit text width (~70ch), use grids |
| No loading states | User sees blank page with no feedback | Always show skeleton/spinner during loading |
| Modals in modals | Stacked overlays confuse users | One modal at a time, or use a slide-out panel |
| Infinite scroll without error handling | Network error = lost content | Pagination with retry button |
| Over-animating | Motion sickness, slow on mobile | prefers-reduced-motion check, keep animations purposeful |
| No empty states | Blank page with no guidance | Show icon + message + action button |
| Hardcoded colors | Can't theme or dark mode | Use CSS variables or Tailwind theme tokens |

---

## 9. shadcn/ui + Radix Pattern

```tsx
// ✅ Button — extends shadcn/ui pattern
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

// Custom variant
<Button
  variant="default"
  size="lg"
  className={cn(
    "bg-brand-600 hover:bg-brand-700",
    "dark:bg-brand-500 dark:hover:bg-brand-400",
    "transition-all duration-150 active:scale-[0.97]"
  )}
>
  Get Started
</Button>

// ✅ Dialog
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';

<Dialog>
  <DialogTrigger asChild>
    <Button variant="outline">Edit Profile</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Edit Profile</DialogTitle>
      <DialogDescription>Make changes to your profile here.</DialogDescription>
    </DialogHeader>
    {/* Form content */}
  </DialogContent>
</Dialog>
```

---

## 10. Verification Checklist

- [ ] Mobile-first responsive (test at 320px, 768px, 1440px)
- [ ] Loading state visible on every data-fetching component
- [ ] Empty state has message + action
- [ ] Error state has message + retry option
- [ ] All images have alt text
- [ ] Forms have labels, error messages, proper focus
- [ ] Keyboard navigation works for all interactive elements
- [ ] Color contrast >= 4.5:1
- [ ] Transitions are 150-300ms with meaningful purpose
- [ ] Dark mode functional (if implemented)
- [ ] No layout shift (CLS < 0.1)
- [ ] Bundle size checked for heavy dependencies
