# Tailwind CSS — Utility-First CSS Framework

Rapid UI development with low-level utility classes.

## Quick Reference

| Concept | Description |
|---------|-------------|
| Utility classes | Single-purpose classes (e.g., `p-4`, `text-center`) |
| JIT mode | Generates only used CSS, tiny bundle |
| Config | `tailwind.config.js` for theme customization |
| Integrations | PostCSS, webpack, Vite, Next.js |

## Config

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class', // or 'media' for prefers-color-scheme
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f9ff',
          500: '#0ea5e9',
          900: '#0c4a6e',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'), // form styling plugin
    require('@headlessui/tailwindcss'), // headless UI integration
  ],
}
```

## PostCSS Integration

```javascript
// postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

## Basic Usage

```html
<div class="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center p-4">
  <div class="max-w-md w-full bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
    <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-4">
      Hello World
    </h1>
    <p class="text-gray-600 dark:text-gray-300 leading-relaxed">
      Tailwind makes styling fast.
    </p>
    <button class="mt-6 w-full bg-brand-500 hover:bg-brand-600 text-white
                   font-semibold py-3 px-6 rounded-xl transition-colors
                   focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2">
      Get Started
    </button>
  </div>
</div>
```

## Dark Mode

```html
<!-- Class-based (recommended) -->
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  ...
</div>

<!-- Toggle button -->
<button
  onClick="document.documentElement.classList.toggle('dark')"
  class="p-2 rounded-lg bg-gray-200 dark:bg-gray-700"
>
  Toggle Dark
</button>
```

## Component Patterns

### Button variants

```html
<!-- Primary -->
<button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg
                font-medium transition-colors focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
  Primary
</button>

<!-- Ghost -->
<button class="text-blue-600 hover:bg-blue-50 px-4 py-2 rounded-lg
                font-medium transition-colors">
  Ghost
</button>

<!-- Icon button -->
<button class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg
                text-gray-600 dark:text-gray-400">
  <svg class="w-5 h-5">...</svg>
</button>
```

### Form inputs

```html
<label class="block">
  <span class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 block">
    Email
  </span>
  <input
    type="email"
    class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600
           rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500
           dark:bg-gray-800 dark:text-white transition-colors"
    placeholder="you@example.com"
  />
  <p class="mt-1 text-sm text-red-500">Email is required</p>
</label>
```

### Card

```html
<div class="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200
            dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow p-6">
  <!-- content -->
</div>
```

## Tailwind with React

```jsx
// Button component
const Button = ({ variant = 'primary', size = 'md', children, className = '', ...props }) => {
  const variants = {
    primary: 'bg-blue-600 hover:bg-blue-700 text-white',
    secondary: 'bg-gray-100 hover:bg-gray-200 text-gray-900 dark:bg-gray-700 dark:hover:bg-gray-600 dark:text-white',
    ghost: 'text-blue-600 hover:bg-blue-50',
  }
  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-lg',
  }
  return (
    <button
      className={`rounded-lg font-medium transition-colors focus:ring-2
                  focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50
                  ${variants[variant]} ${sizes[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  )
}
```

## Responsive Design

```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- Cards -->
</div>

<!-- Typography scale -->
<h1 class="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight">
  Responsive Heading
</h1>
```

## Animation

```html
<div class="animate-spin">...</div>
<div class="animate-pulse">...</div>
<div class="animate-bounce">...</div>

<!-- Custom animation in config -->
<!-- Add to theme.extend.animation -->
<!-- .spin-slow { animation: spin 2s linear infinite; } -->
```

## Headless UI (Unstyled Components)

```bash
npm install @headlessui/react
```

```jsx
import { Menu } from '@headlessui/react'

<Menu>
  <Menu.Button className="flex items-center gap-2 px-4 py-2 bg-gray-100 rounded-lg">
    Options
  </Menu.Button>
  <Menu.Items className="absolute mt-2 bg-white shadow-lg rounded-lg border">
    <Menu.Item>
      {({ active }) => (
        <button className={`w-full text-left px-4 py-2 ${active ? 'bg-blue-50' : ''}`}>
          Edit
        </button>
      )}
    </Menu.Item>
  </Menu.Items>
</Menu>
```

## Heroicons

```bash
npm install @heroicons/react
```

```jsx
import { BeakerIcon } from '@heroicons/react/24/solid'

<BeakerIcon className="h-6 w-6 text-blue-500" />
```

## Resources

- [awesome-tailwindcss](https://github.com/aniftyco/awesome-tailwindcss)
- [tailwindcss.com/docs](https://tailwindcss.com/docs)