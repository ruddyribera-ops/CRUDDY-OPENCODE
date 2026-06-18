# auth.md Discovery — Agent Registration Protocol

**Purpose:** How OpenCode agents discover, register, and authenticate to services
via the auth.md protocol (IETF draft `draft-ietf-oauth-identity-assertion-authz-grant-04`).

## Discovery Flow

1. **Check for auth.md support:** Query `/.well-known/oauth-protected-resource` (RFC 9728)
   → If response includes `agent_auth` block, the service supports auth.md
2. **Find AS:** Extract `authorization_server` from `agent_auth` block
   → Query `/.well-known/oauth-authorization-server` for registration endpoints
3. **Register agent:** POST ID-JAG to `agent_registration_endpoint`
   → Receive API key / credential set

## ID-JAG Format
- Signed ES256 JWT, 5-min TTL
- Claims: `iss` (provider = main-coordinator), `sub` (agent name + task ID), `jti` (replay protection)
- Signed with coordinator's private key (see JWKS at `.well-known/jwks.json`)

## Trusted Services
- Hardcoded in `opencode.json` → `agent_identity.services` block
- Services confirmed supporting auth.md: Cloudflare, Firecrawl, Resend, Monday.com
- Others discovered dynamically via `.well-known` probe

## Fallback
- If auth.md not supported: use existing manual API key flow
- If registration fails: retry once with exponential backoff, then fall back to manual
