---
name: realtime-patterns
description: WebSocket, Server-Sent Events, polling, and live update patterns
tags: [realtime, websocket, sse, backend]
---

version: 1.0.0
---
version: 1.0.0
platforms: [windows, macos, linux]
---
version: 1.0.0
---
version: 1.0.0
platforms: [windows, macos, linux]
---
# Real-time Patterns

## WebSocket on Same Port as Express
```javascript
import express from 'express';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';

const app = express();
const server = createServer(app);
const wss = new WebSocketServer({ server });

// Shared HTTP + WebSocket on port 3001
app.use(express.json());

// REST endpoints...
app.get('/api/status', (req, res) => res.json({ status: 'ok' }));

// WebSocket handling
wss.on('connection', (ws) => {
  console.log('Client connected');
  ws.on('message', (data) => {
    // Handle incoming messages
  });
});

// Broadcast to all connected clients
function broadcast(message) {
  const data = JSON.stringify(message);
  wss.clients.forEach(client => {
    if (client.readyState === 1) client.send(data);
  });
}

server.listen(3001);
```

## Frontend WebSocket Hook
```javascript
const connect = () => {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const ws = new WebSocket(`${protocol}//${window.location.host}/ws`);

  ws.onopen = () => setConnected(true);
  ws.onclose = () => {
    setConnected(false);
    // Reconnect after 3 seconds
    setTimeout(connect, 3000);
  };

  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    onMessage(data);
  };
};
```

## Polling (Simpler Alternative)
```javascript
// Poll every 5 seconds
useEffect(() => {
  const interval = setInterval(async () => {
    const data = await fetch('/api/status').then(r => r.json());
    setStatus(data);
  }, 5000);
  return () => clearInterval(interval);
}, []);
```

## When to Use What
| Pattern | Use Case |
|---------|----------|
| WebSocket | Chat, live feeds, real-time collaboration |
| Server-Sent Events | One-way server→client updates |
| Polling | Infrequent updates, simpler setup |

## Broadcast Events (Common Pattern)
```javascript
// On the server when data changes
broadcast({ type: 'ITEM_UPDATED', data: { id: 1, name: 'Updated' } });

// Frontend handles by type
ws.onmessage = (event) => {
  const { type, data } = JSON.parse(event.data);
  switch(type) {
    case 'ITEM_UPDATED': refreshItem(data); break;
    case 'NEW_MESSAGE': addMessage(data); break;
  }
};
```

---

## Enriched Content — Real-time Pattern Libraries & Integration

### WebSocket Libraries

| Library | Stack | Key feature |
|---------|-------|-------------|
| ws | Node.js | Minimal, ~8K gzip, no dependencies |
| socket.io | Node.js + client | Auto-reconnect, fallbacks, rooms |
| uWebSockets.js | Node.js | C++ core, 10x throughput vs ws |
| fastify-websocket | Node.js (Fastify) | Plugin, auto-route upgrade |
| ws-cluster | Node.js | Redis-backed multi-process WS |
| tokio-tungstenite | Rust (Tokio) | Async WebSocket server |
| aiohttp | Python (async) | WebSocket + HTTP on same port |

### SSE (Server-Sent Events)

| Tool/Pattern | Notes |
|------|-------|
| `EventSource` (browser API) | Native, no library needed |
| fastify-sse | Fastify plugin for SSE |
| sse-channel | Node.js, channel-based broadcasting |
| labstack/eventsource | Go (Echo framework) |
| Railway caution | SSE uses HTTP long-poll, works through Railway proxy |

### Pub/Sub Backends

| Backend | Protocol | Best for |
|---------|----------|----------|
| Redis Pub/Sub | In-memory | Simple, low-latency, same Redis as cache |
| NATS | Lightweight messaging | High throughput, TLS, NAC |
| RabbitMQ | AMQP 0-9-1 | Routing, durability, delayed queues |
| Apache Kafka | Log-based streaming | Event sourcing, replay, high volume |
| ioredis (Node) | Redis client | `ioredis` cluster support, Sentinel |

**Redis Pub/Sub + WebSocket pattern:**
```javascript
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import Redis from 'ioredis';

const pub = new Redis();
const sub = new Redis();
const wss = new WebSocketServer({ server });

sub.subscribe('events');
sub.on('message', (channel, message) => {
  wss.clients.forEach(client => {
    if (client.readyState === 1) client.send(message);
  });
});
```
This lets multiple server processes share real-time state — publish once, broadcast everywhere.

### Real-time Database Backends

| Service | Protocol | Self-host? | Notes |
|---------|----------|------------|-------|
| Supabase Realtime | WebSocket + PostgreSQL replication | ✓ | LISTEN/NOTIFY + logical replication |
| Firebase Realtime DB | WebSocket | ✗ | Google's real-time DB |
| deepstream | WebSocket, custom protocol | ✓ | Data sync + RPC |
| Ably | WebSocket, MQTT | ✗ | Enterprise, global edge network |

### GraphQL Subscriptions

| Library | Transport | Notes |
|---------|-----------|-------|
| graphql-ws | WebSocket-only | Successor to subscriptions-transport-ws |
| subscriptions-transport-ws | WebSocket | Legacy, still widely used |
| Apollo GraphQL Subscriptions | WS + Redis | PubSub engines for scale |

### WebRTC (Peer-to-Peer Real-time)

| Library | Use case | Notes |
|---------|----------|-------|
| PeerJS | Simple P2P app | Easy signaling server |
| simple-peer | Node + browser | Minimal, composable |
| mediasoup | SFU conferencing | Selective forwarding unit |
| LiveKit | Production video/audio | Cloud or self-hosted SFU |
| Daily.co | Embedded video | Managed + custom branding |

### Real-time Patterns Cheat Sheet

**Backpressure handling**
```javascript
// Don't let slow consumers block the server
const canSend = ws.bufferedAmount === 0;
if (!canSend) {
  // Drop, buffer, or throttle this client
}
```

**Reconnection strategies**
| Strategy | Delay formula | Use case |
|----------|---------------|----------|
| Fixed | 3s constant | Simple, predictable |
| Linear backoff | n × 1s | Moderate retry |
| Exponential backoff | min(2^n, 30s) | Server overload |
| Jittered backoff | random(0, min(2^n, 30s)) | Thundering herd prevention |

**Heartbeat / ping-pong**
```javascript
// Server (ws library)
const interval = setInterval(() => {
  wss.clients.forEach(ws => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on('connection', ws => {
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });
});
```

**Message ordering guarantees**
- TCP guarantees order (WebSocket uses TCP)
- Kafka: ordered per partition
- Redis Pub/Sub: ordered within a single client connection
- NATS: ordered per subject (at-most-once)
- RabbitMQ: ordered per queue

**Railway-compatible considerations:**
- Railway's TCP proxy blocks WebSocket upgrade for some plans
- Fallback to SSE or polling when WS fails
- Check `window.location.protocol` to determine `ws://` vs `wss://`

**Full connection lifecycle:**
```
Connect → Heartbeat ↔ Ping/Pong → Reconnect on close → Cleanup on unmount
```

**When to break WebSocket into a separate service:**
- More than 1000 concurrent connections per process
- Need to scale reads/writes independently
- Want different release cadence for real-time vs REST
## Do Not Use
- REST API design (use api-patterns)
- Database operations (use database-patterns)
- UI implementation (use frontend-dev)
- Deployment configuration (use deployment-patterns)
