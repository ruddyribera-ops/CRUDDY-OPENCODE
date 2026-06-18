---
name: realtime-patterns
description: WebSocket, Server-Sent Events (SSE), polling, and live update patterns. Covers connection management, reconnection strategies, broadcasting, and Railway-specific WebSocket quirks.
triggers: websocket, sse, realtime, live, broadcast, polling, events, streaming
auto_load: code-builder
---

# Real-Time Patterns

## WebSocket
- **Connection**: auto-reconnect with exponential backoff (1s, 2s, 4s, max 30s)
- **Heartbeat**: ping/pong every 30s to detect stale connections
- **Broadcast**: use rooms/channels, not global broadcast
- **Railway**: TCP proxy requires explicit config — WebSocket may not work on free tier

## Server-Sent Events (SSE)
- Prefer SSE over WebSocket for unidirectional server→client
- `text/event-stream` content type, `Cache-Control: no-cache`
- Auto-reconnect via `EventSource` API (built-in browser support)

## Polling (Fallback)
- Only when WebSocket/SSE unavailable
- Exponential backoff between polls (min 5s, max 60s)
- Conditional requests with `ETag` or `Last-Modified`

## Connection Lifecycle
1. Connect → 2. Auth (if applicable) → 3. Subscribe → 4. Heartbeat loop → 5. Clean disconnect
- Always clean up on unmount/abort
- Log reconnection attempts (don't spam — log every 3rd attempt)
