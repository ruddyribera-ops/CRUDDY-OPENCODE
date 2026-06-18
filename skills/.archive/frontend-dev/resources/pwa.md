# Progressive Web Apps (PWA) & Service Workers

Installable, offline-capable web applications.

## Service Workers

### Lifecycle

```
Install → Activate → Fetch (event-driven)
```

### Register

```javascript
// main.js
if ('serviceWorker' in navigator) {
  window.addEventListener('load', async () => {
    const reg = await navigator.serviceWorker.register('/sw.js')
    console.log('SW registered:', reg.scope)
  })
}
```

### Basic Service Worker

```javascript
// sw.js (at root: /sw.js)
const CACHE_NAME = 'v1'
const ASSETS = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
  '/images/logo.png',
]

// Install — cache assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting()) // Activate immediately
  )
})

// Activate — clean old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  )
})

// Fetch — serve from cache, fall back to network
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(cached => cached || fetch(event.request)
  )
})
```

## Caching Strategies

| Strategy | When to Use | Code |
|----------|-------------|------|
| **Cache First** | Static assets, CDN resources | Check cache → network fallback |
| **Network First** | API data, user-specific content | Try network → cache fallback |
| **Stale-While-Revalidate** | Balance of freshness + speed | Return cached, fetch update in background |
| **Cache Only** | Versioned assets only | Only from cache |

### Stale-While-Revalidate (Recommended)

```javascript
self.addEventListener('fetch', event => {
  const cacheKey = event.request

  event.respondWith(
    caches.open(CACHE_NAME).then(async cache => {
      const cachedResponse = await cache.match(cacheKey)

      const fetchPromise = fetch(cacheKey).then(networkResponse => {
        if (networkResponse.ok) {
          cache.put(cacheKey, networkResponse.clone())
        }
        return networkResponse
      }).catch(() => null)

      return cachedResponse || fetchPromise
    })
  )
})
```

### Network First (API calls)

```javascript
self.addEventListener('fetch', event => {
  if (!event.request.url.includes('/api/')) return

  event.respondWith(
    fetch(event.request)
      .then(response => {
        if (response.ok) {
          const clone = response.clone()
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone))
        }
        return response
      })
      .catch(() => caches.match(event.request))
  )
})
```

## Web App Manifest

```json
// public/manifest.json
{
  "name": "My App",
  "short_name": "MyApp",
  "description": "A fantastic PWA",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0ea5e9",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### Link in HTML

```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0ea5e9">
```

## Workbox (Google's PWA Library)

```bash
npm install workbox-webpack-plugin
```

```javascript
// webpack.config.js
const { GenerateSW } = require('workbox-webpack-plugin')

module.exports = {
  plugins: [
    new GenerateSW({
      clientsClaim: true,
      skipWaiting: true,
      runtimeCaching: [
        {
          urlPattern: /^https:\/\/api\.example\.com\//,
          handler: 'NetworkFirst',
          options: {
            cacheName: 'api-cache',
            networkTimeoutSeconds: 10,
          },
        },
        {
          urlPattern: /\.(?:png|jpg|jpeg|svg|gif)$/,
          handler: 'CacheFirst',
          options: {
            cacheName: 'image-cache',
            expiration: { maxEntries: 100 },
          },
        },
      ],
    }),
  ],
}
```

## Offline-First with IndexedDB

```javascript
// Using idb-keyval (simple)
import { set, get, del, keys } from 'idb-keyval'

// Save for offline
async function saveOffline(key, value) {
  await set(key, value)
}

// Load from cache first, fall back to network
async function getWithOffline(key, fetcher) {
  const cached = await get(key)
  if (cached) return cached

  const fresh = await fetcher()
  await set(key, fresh)
  return fresh
}
```

## Background Sync

```javascript
// Register sync when offline
navigator.serviceWorker.ready.then(reg => {
  document.getElementById('sendBtn').addEventListener('click', async () => {
    const data = { message: document.getElementById('msg').value }

    // Queue if offline
    const sync = await reg.sync.register('send-message')
    if (!sync) {
      // Online — send immediately
      await fetch('/api/messages', {
        method: 'POST',
        body: JSON.stringify(data),
        headers: { 'Content-Type': 'application/json' }
      })
    }
  })
})

// sw.js — process queued items
self.addEventListener('sync', event => {
  if (event.tag === 'send-message') {
    event.waitUntil(sendQueuedMessages())
  }
})
```

## Push Notifications

```javascript
// Request permission
const permission = await Notification.requestPermission()

// Subscribe to push
const subscription = await registration.pushManager.subscribe({
  userVisibleOnly: true,
  applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
})

await fetch('/api/push/subscribe', {
  method: 'POST',
  body: JSON.stringify(subscription)
})
```

## PWA Auditing

```bash
# Lighthouse PWA score
npx lighthouse https://myapp.com --only-categories=pwa

# PWABuilder
# https://www.pwabuilder.com/
```

## Resources

- [awesome-pwa](https://github.com/TalAter/awesome-progressive-web-apps)
- [serviceworkers.io](https://serviceworkerspec.org)
- [Workbox](https://developer.chrome.com/docs/workbox/)