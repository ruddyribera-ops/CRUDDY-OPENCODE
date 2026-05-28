# Web Security

Complete web application security guide covering OWASP Top 10, defense in depth, and secure architecture patterns.

## OWASP Top 10 (2021)

| # | Category | Description | Key Defense |
|---|----------|-------------|-------------|
| A01 | Broken Access Control | Users accessing unauthorized resources | Force proper authorization at every endpoint; deny by default |
| A02 | Cryptographic Failures | Sensitive data exposure (unencrypted data, wrong crypto) | Encrypt all sensitive data at rest and in transit; use strong hashes (bcrypt, argon2) |
| A03 | Injection | SQL, NoSQL, OS, LDAP injection | Parameterized queries, input validation, context-aware output encoding |
| A04 | Insecure Design | Missing security controls, business logic flaws | Threat modeling, secure design patterns, secure defaults |
| A05 | Security Misconfiguration | Default configs, verbose errors, unnecessary features | Hardened images, automated config verification, minimal attack surface |
| A06 | Vulnerable Components | Using components with known CVEs | Bill of Materials (SBOM), automated dependency scanning, active maintenance |
| A07 | Auth Failures | Weak passwords, improper session handling | Multi-factor auth, secure session management, password strength enforcement |
| A08 | Data Integrity Failures | Unsigned code, unverified config | Code signing, artifact verification, integrity checks |
| A09 | Logging Failures | No audit trail, undetected breaches | Centralized logging, alerting on suspicious patterns, SIEM integration |
| A10 | SSRF | Server fetching remote resources without validation | Deny by default, allowlist for internal services, network segmentation |

## Defense in Depth

Layer your defenses so a single point of failure doesn't compromise the entire system:

1. **Network layer**: Firewall, WAF, DDoS protection, VPN
2. **Transport layer**: TLS 1.2+, HSTS, certificate pinning
3. **Application layer**: Input validation, output encoding, secure session management
4. **Data layer**: Encryption at rest, field-level encryption, key management (HMAC for integrity)
5. **Monitoring layer**: SIEM, anomaly detection, alerting, incident response plan

## Content Security Policy (CSP)

A strong CSP header prevents XSS by controlling what resources the browser can load:

```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{RANDOM}'; style-src 'self'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://api.yoursite.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
```

**Directives:**
- `default-src 'self'` — fallback for all resource types
- `script-src 'self' 'nonce-{RANDOM}'` — allow only self-hosted scripts with nonce
- `frame-ancestors 'none'` — prevent clickjacking
- `form-action 'self'` — restrict form submissions to same origin

**Report violations:**
```http
Content-Security-Policy-Report-Only: default-src 'self'; report-uri /csp-violation-report
```

## CORS Configuration

```javascript
// Node.js / Express — never use '*' with credentials
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN, // specific origin, not '*'
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400
}));
```

**Rules:**
- Never use `Access-Control-Allow-Origin: *` for APIs that handle sessions or auth
- Use `Vary: Origin` when you dynamically set allowed origins
- Preflight caching: `Access-Control-Max-Age: 86400` for non-credentialed requests

## HTTP Security Headers

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## Input Validation Patterns

```javascript
// Express.js — use a whitelist approach
const Joi = require('joi');

const schema = Joi.object({
  email: Joi.string().email().max(255).required(),
  username: Joi.string().alphanum().min(3).max(30).required(),
  age: Joi.number().integer().min(13).max(120),
  role: Joi.string().valid('admin', 'user', 'moderator')
});

const { error, value } = schema.validate(req.body, { abortEarly: false });
if (error) return res.status(400).json({ errors: error.details.map(d => d.message) });
```

**Rules:**
- Define allowed characters explicitly; reject everything else
- Validate type, length, format, range
- Sanitize HTML with DOMPurify or similar before rendering
- Never rely on client-side validation alone

## Output Encoding

Context-aware encoding prevents XSS in all output contexts:

| Context | Encoding | Example |
|---------|----------|---------|
| HTML body | HTML entities | `<` → `&lt;` |
| HTML attribute | HTML entities or double quotes | `"` → `&quot;` |
| JavaScript | JavaScript hex escape or JSON | `<script>` → `\x3cscript\x3e` |
| URL parameter | URL encoding | `&` → `%26` |
| CSS | CSS escape | `\` → `\\` |
| SQL | Parameterized queries | Never interpolate user input |

```javascript
// Node.js — safe HTML rendering
const he = require('he'); // HTML entity encoding
const sanitized = he.escape(userInput); // for HTML context

// For React, automatic contextual encoding via JSX
// For template engines (EJS, Jinja2), use auto-escaping + mark safe only when needed
```

## SameSite Cookies

```http
Set-Cookie: sessionId=abc123; HttpOnly; Secure; SameSite=Strict
```

- `SameSite=Strict` — only sent on same-site requests (best for sensitive actions)
- `SameSite=Lax` — sent on top-level navigations, safe for most apps
- `SameSite=None` — required for cross-site APIs, must use with `Secure`

## Rate Limiting

```javascript
// Express — use a rate limiter middleware
const rateLimit = require('express-rate-limit');
const crypto = require('crypto');

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip + (req.user?.id || ''), // per user + ip
  skip: (req) => req.path === '/health' // skip health checks
});

app.use('/api', apiLimiter);

// For login pages, stricter limit
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // only 5 attempts per 15 min
  message: 'Too many login attempts, try again later'
});
```

## SSRF Prevention

```javascript
// Node.js — never let user control fetch destinations
const URL = require('url').URL;

// Option 1: Block private IP ranges at the DNS resolution level
const blockedRanges = [
  '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '127.0.0.0/8', '169.254.0.0/16'
];

async function isBlockedIP(urlStr) {
  const url = new URL(urlStr);
  const { hostname } = url;
  const ips = await dns.resolve4(hostname); // resolve DNS first
  return ips.some(ip => blockedRanges.some(range => isInCIDR(ip, range)));
}

// Option 2: Allowlist domains (preferred for external APIs)
const allowedExternal = ['api.stripe.com', 'api.github.com'];
if (!allowedExternal.includes(new URL(url).hostname)) {
  throw new Error('Disallowed external host');
}
```

## Security Checklist

- [ ] All traffic over HTTPS with TLS 1.2+
- [ ] CSP header configured with nonce or hash
- [ ] Security headers: HSTS, X-Frame-Options, X-Content-Type-Options
- [ ] Input validation on all endpoints (whitelist, not blocklist)
- [ ] Output encoding in all render paths
- [ ] Parameterized queries for all DB operations
- [ ] Auth: bcrypt (cost factor 12+), secure session cookies (HttpOnly, Secure, SameSite)
- [ ] Rate limiting on auth and sensitive endpoints
- [ ] SSRF protection: allowlist, no private IP range fetching
- [ ] Dependencies scanned for CVEs (npm audit, dependabot, Snyk)
- [ ] Secrets in env vars, never in source control
- [ ] Access control: deny by default, least privilege
- [ ] Logs: auth failures, access control denials, sensitive operations