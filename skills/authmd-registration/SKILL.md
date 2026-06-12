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

## CLI Tool
Use `scripts/authmd-register.js` for all registration operations:

```bash
# List all configured services and their credential status
node scripts/authmd-register.js list

# Discover registration endpoint for a URL
node scripts/authmd-register.js discover --url https://api.firecrawl.ai

# Register a service (mints ID-JAG, POSTs to registration endpoint)
node scripts/authmd-register.js register --service cloudflare

# Revoke a service registration
node scripts/authmd-register.js revoke --service cloudflare
```

## Prerequisites
- `scripts/agent-identity.js` installed and configured
- `opencode.local.json` with `agent_identity` block
- `.well-known/jwks.json` exported (`node agent-identity.js jwks`)

## Manual Discovery Flow (if CLI unavailable)

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

## Configured Services (from opencode.local.json)
Services known to support auth.md: Cloudflare, Firecrawl, Resend, Monday.com

Each service entry includes:
- `base_url`: API base URL
- `discovery_url`: Path to oauth-protected-resource
- `authorization_server`: OAuth authorization server URL
- `registration_endpoint`: Full URL for agent registration
- `credential_path`: Where to store the received API key
- `capabilities`: Array of read/write permissions

## Credential Storage
Credentials are stored as JSON at `credential_path`:
```json
{
  "api_key": "...",
  "registered_at": "2026-06-10T12:00:00.000Z",
  "expires_at": null
}
```

## Error Handling
- **Private key not found**: Run `node scripts/agent-identity.js init`
- **JWKS not exported**: Run `node scripts/agent-identity.js jwks`
- **HTTP 401/403 on register**: Check JWKS export is current
- **HTTP 404 on discover**: Service does not support auth.md — fallback to manual API key
- **Network timeout**: Logged but non-fatal; local credential deletion attempted on revoke
- **Credential file missing on revoke**: Exit with error (nothing to revoke)

## Fallback
If the service does not support auth.md, use the existing manual API key flow
(env vars or .env file per project convention).
