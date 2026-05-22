# Modern Frontend Frameworks

Svelte, Next.js, Blazor (WebAssembly), and Yew (Rust→Wasm).

## Svelte / SvelteKit

### Svelte 5 (Runes)

```svelte
<!-- Counter.svelte -->
<script>
  let count = $state(0)      // Reactive state
  let doubled = $derived(count * 2)  // Derived

  function increment() {
    count++
  }
</script>

<button onclick={increment}>
  Count: {count}, doubled: {doubled}
</button>
```

### SvelteKit (Full Framework)

```bash
npm create svelte@latest myapp
cd myapp
npm install
npm run dev
```

```svelte
<!-- src/routes/+page.svelte -->
<script>
  export let data
</script>

<h1>{data.title}</h1>
<p>{data.content}</p>
```

```javascript
// src/routes/+page.server.js
export async function load() {
  return {
    title: 'My Page',
    content: await fetchContent()
  }
}
```

### SvelteKit Routing

```
src/routes/
├── +layout.svelte       # Shared layout
├── +layout.server.js     # Server-side layout data
├── +page.svelte         # Home page (/)
├── about/
│   └── +page.svelte     # /about
├── blog/
│   ├── +page.svelte     # /blog
│   └── [slug]/
│       ├── +page.svelte  # /blog/my-post
│       └── +page.server.js
└── api/
    └── users/
        └── +server.js    # /api/users (REST endpoint)
```

## Next.js (App Router)

### App Router Structure

```
app/
├── layout.tsx            # Root layout (persists across routes)
├── page.tsx              # Home (/)
├── about/
│   └── page.tsx          # /about
├── dashboard/
│   ├── layout.tsx        # Dashboard-specific layout
│   └── page.tsx          # /dashboard
├── api/
│   └── users/
│       └── route.ts      # /api/users (Route Handler)
├── loading.tsx           # Loading UI
├── error.tsx             # Error boundary
└── not-found.tsx        # 404 page
```

### Server Components (Default)

```tsx
// app/users/page.tsx — Server Component (default, no 'use client')
import { db } from '@/lib/db'

export default async function UsersPage() {
  const users = await db.user.findMany()

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  )
}
```

### Client Components

```tsx
// app/dashboard/counter.tsx — Client Component
'use client'  // Required for hooks, event handlers

import { useState } from 'react'

export function Counter({ initial = 0 }) {
  const [count, setCount] = useState(initial)
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  )
}
```

### API Routes

```ts
// app/api/users/route.ts
import { NextResponse } from 'next/server'
import { db } from '@/lib/db'

export async function GET() {
  const users = await db.user.findMany()
  return NextResponse.json(users)
}

export async function POST(request: Request) {
  const body = await request.json()
  const user = await db.user.create({ data: body })
  return NextResponse.json(user, { status: 201 })
}
```

### Next.js Image

```tsx
import Image from 'next/image'

<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority  // Preload above-fold images
  className="rounded-xl"
/>
```

### Incremental Static Regeneration (ISR)

```tsx
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await getAllPosts()
  return posts.map(post => ({ slug: post.slug }))
}

export const revalidate = 3600 // Revalidate every hour

export default async function PostPage({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug)
  return <article>{post.content}</article>
}
```

## Blazor (WebAssembly)

### Project Setup

```bash
dotnet new blazorwasm -o BlazorApp
cd BlazorApp
dotnet run
```

### Component

```razor
@page "/counter"

<PageTitle>Counter</PageTitle>

<h1>Counter</h1>

<p role="status">Current count: @currentCount</p>

<button class="btn btn-primary" @onclick="IncrementCount">
    Click me
</button>

@code {
    private int currentCount = 0;

    private void IncrementCount()
    {
        currentCount++;
    }
}
```

### Blazor Server vs WebAssembly

| Aspect | Blazor Server | Blazor WASM |
|--------|---------------|-------------|
| Runtime | Server (SignalR) | Browser (WASM) |
| Initial load | Fast | Larger bundle |
| Offline | No | Yes |
| API calls | Less | More |

## Yew (Rust → WebAssembly)

### Project Setup

```bash
npm install -g trunk
cargo install wasm-pack
wasm-pack build --target web
```

### Component

```rust
use yew::prelude::*;

#[function_component(App)]
fn app() -> Html {
    let counter = use_state(|| 0);

    let increment = {
        let counter = counter.clone();
        Callback::from(move |_| counter.set(*counter + 1))
    };

    html! {
        <div>
            <p>{ format!("Count: {}", *counter) }</p>
            <button onclick={increment}>{ "Increment" }</button>
        </div>
    }
}
```

## Framework Comparison

| Framework | Server Rendering | Type Safety | Bundle | Learning Curve |
|-----------|-----------------|-------------|--------|----------------|
| **Svelte/SvelteKit** | SSR + SSG | TypeScript | Small | Low |
| **Next.js** | SSR + SSG + ISR | TypeScript | Medium | Medium |
| **Blazor WASM** | WASM | C# | Large | Medium |
| **Yew** | WASM | Rust | Medium | High |

## Resources

- [awesome-svelte](https://github.com/TheComputerM/awesome-svelte)
- [awesome-nextjs](https://github.com/unicodeveloper/awesome-nextjs)