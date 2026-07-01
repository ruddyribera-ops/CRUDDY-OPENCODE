---
name: WebSocket + Railway debugging
description: WebSocket proxy failure on Railway TCP gateway — patterns for Palma Coin and any Railway WS app
type: feedback
---

# WebSocket on Railway: TCP Gateway Limits

**Problem:** `ws://` connects but immediately errors/disconnects in Railway production.

**Why:** Railway's HTTP router does not proxy WebSocket upgrade handshakes. Local `ws://localhost:PORT/ws` works; Railway `wss://app.up.railway.app/ws` connects then drops.

## Diagnosis Checklist

1. **Confirm it's a proxy problem, not a server problem:**
   ```bash
   # From a machine outside Railway
   wscat -c "wss://palma-coin-production.up.railway.app/ws"
   # If "Connected" then "Disconnected" → Railway proxy issue
   # If "Refused" → server not listening or wrong port
   ```

2. **Check Railway logs for the upgrade request:**
   - Should see `GET /ws` with `Upgrade: websocket` header
   - If not present → Railway dropped the upgrade request

3. **Verify PORT env var is correct** — Railway injects `PORT`; hardcoded ports fail silently

## Workarounds (Priority Order)

### Option A — Switch to Server-Sent Events (SSE) for read-only streams
- Best for: live student coin updates, leaderboard refreshes, notifications
- No special Railway config needed
- One-way (server → client only)
```js
// Server (Express)
app.get('/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  const interval = setInterval(() => res.write(`data: ${JSON.stringify(update)}\n\n`), 1000)
  req.on('close', () => clearInterval(interval))
})
// Client
const es = new EventSource('/events')
es.onmessage = (e) => updateUI(JSON.parse(e.data))
```

### Option B — Long Polling (simplest fallback)
- Poll every 2-3s via regular HTTP
- No proxy issues, works everywhere
- Fine for non-real-time use cases (coin balance, votes)

### Option C — Railway TCP Service (if bidirectional required)
- Add a separate Railway service as a TCP proxy
- More complex, only worth it for true bidirectional (e.g., student voting)
- See Railway docs: Private Networking + TCP Proxy

## Palma Coin Specific Status

- `/ws` endpoint: built, works locally, broken on Railway
- Current workaround: none — live updates silently fail
- Recommended path: SSE for coin updates + HTTP polling for votes
- Tracked in `project_active.md` under Palma Coin known issues

## How to Apply

When working on any Railway-deployed real-time feature:
1. Never promise WebSocket will work on Railway without testing first
2. Default to SSE for server-push scenarios
3. Default to polling for low-frequency updates
4. Only escalate to TCP proxy if truly bidirectional and high-frequency
