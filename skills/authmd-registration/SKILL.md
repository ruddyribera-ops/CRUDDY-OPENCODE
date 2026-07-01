---
name: authmd-registration
description: "auth.md protocol — agent registration and authentication for external services (Cloudflare, Firecrawl, Resend, Monday.com). Two-hop discovery, ID-JAG presentation, credential caching, and fallback to manual API keys. Use when agents need to register with or authenticate to external services."
triggers:
  - auth.md
  - agent registration
  - service authentication
  - ID-JAG
  - credential injection
  - external service auth
applies_to:
  - main-coordinator
  - account-manager
  - any agent calling external MCP services
---

# Auth.md Registration

## When to use this

Load this skill when:

- An agent needs to authenticate to an external service (Cloudflare, Firecrawl, Resend, Monday.com)
- You're setting up ID-JAG (Identity JWT for Agent) tokens for credential injection
- You need to cache credentials for repeated service calls
- A service rejects a credential and you need to fall back to manual API keys
- You're building cross-agent authentication flows

Do NOT use this skill when:

- Authenticating to a local service (no auth needed)
- The service uses simple API keys that are already in env vars (just call it)
- Setting up OAuth for human users (different flow)

---

## Auth.md Protocol — Core Flow

The auth.md protocol has 4 phases:

### 1. Two-hop discovery

Agent → Service Registry → JWKS endpoint

The agent first discovers what services are available and what auth scheme they use.

```
GET https://service.example/.well-known/auth.md
→ Returns: { auth_scheme: "id-jag", jwks_url: "..." }
```

### 2. ID-JAG presentation

Agent presents its identity token (signed JWT) to the service:

```
POST /auth/token
Authorization: Bearer <id-jag-token>
→ Returns: { access_token: "...", expires_in: 3600 }
```

### 3. Credential caching

Store the access_token locally with its expiry. Reuse until expiry to avoid re-authentication.

```python
cache = {
    "service_id": {
        "access_token": "...",
        "expires_at": "2026-06-29T20:00:00Z",
    }
}
```

### 4. Fallback to manual API keys

If ID-JAG fails (service doesn't support it, JWKS endpoint down), fall back to env-var API keys:

```python
api_key = os.environ.get("SERVICE_API_KEY")
if not api_key:
    raise AuthError("No ID-JAG and no API key")
```

---

## Cross-references

- `rules/loop-operator-safety.md` — for batched auth attempts
- `plugins/sub-agent-guard.js` — for timeout-bounded auth flows
- `opencode.json` — for MCP server auth configuration

---

## Status

Starter skill (created 2026-06-29). Real implementation requires actual auth.md endpoint integration; this is the protocol reference.