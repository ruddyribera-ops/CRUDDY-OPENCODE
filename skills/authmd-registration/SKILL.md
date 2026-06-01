---
name: authmd-registration
description: |
  auth.md protocol — agent registration and authentication
  for external services. Two-hop discovery, ID-JAG presentation,
  credential caching, and fallback to manual API keys.
triggers:
  - register with
  - auth.md
  - id-jag
  - agent registration
  - service authentication
  - get api key for
  - discover service
---

# auth.md Registration — Agent Service Onboarding

## When to Use
When an agent needs to authenticate to an external service (Cloudflare, Firecrawl, Resend, etc.)
and the service supports the auth.md protocol.

## Prerequisites
- `scripts/agent-identity.js` installed and configured
- `opencode.local.json` with `agent_identity` block
- `.well-known/jwks.json` exported (`node agent-identity.js jwks`)

## Discovery Flow

### 1. Check service support
```
GET /.well-known/oauth-protected-resource
→ Look for `agent_auth` block in response
```

### 2. Find authorization server
```
GET {authorization_server}/.well-known/oauth-authorization-server
→ Look for `agent_registration_endpoint`
```

### 3. Present ID-JAG
```bash
# Mint identity token
ID_JAG=$(node scripts/agent-identity.js mint --sub "$AGENT_NAME" --task-id "$TASK_ID")

# Register with service
curl -X POST "$REGISTRATION_ENDPOINT" \
  -H "Content-Type: application/jwt" \
  -H "X-ID-JAG: $ID_JAG" \
  -d '{"agent_name": "'"$AGENT_NAME"'", "capabilities": ["read", "write"]}'
```

### 4. Handle response
- **200 OK** → API key received → cache in session memory
- **401 Unauthorized** → JWKS missing or expired → run `node agent-identity.js jwks` first
- **404 / not supported** → fallback to manual API key

## Trusted Services (from opencode.local.json)
Services known to support auth.md: Cloudflare, Firecrawl, Resend, Monday.com

## Credential Cache
Received API keys are stored in the coordinator's session state for the task duration.
Do NOT persist beyond the session — re-register each session.

## Fallback
If the service does not support auth.md, use the existing manual API key flow
(env vars or .env file per project convention).
