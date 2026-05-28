# Security Tools & Ecosystem

## Web Security — OWASP Top 10 Mitigation
| Class | Prevention | Tools |
|-------|------------|-------|
| Broken Access Control | RBAC/ABAC, deny-by-default | OPA, Casbin, permit.io |
| Cryptographic Failures | Modern libs, never roll your own | Tink, libsodium, BoringSSL |
| Injection | Parameterized queries, ORM | ESLint, SQLMap detection |
| Insecure Design | Threat modeling, rate limiting | OWASP Threat Dragon |
| Security Misconfiguration | Hardened defaults | docker-bench-security, OpenSCAP |
| Vulnerable Components | SBOM + auto-patching | Dependabot, Renovate, Trivy |
| Auth Failures | MFA, passwordless, OAuth2 | WebAuthn, Ory Hydra, Authelia |
| Data Integrity | Signatures, SRI, code signing | Subresource Integrity, Sigstore |
| Logging Failures | Structured audit logging | ELK, Loki, SigNoz |
| SSRF | URL allowlist, deny private IPs | go-validator, SSRF Shield |

## Network Scanning
| Tool | Type | Key Feature |
|------|------|-------------|
| Nmap | Port/Service discovery | NSE scripting |
| RustScan | Port scan | 10x faster than Nmap |
| Nuclei | Vulnerability scanner | 10K+ YAML templates |
| ZAP | Web app scanner | OWASP ZAP, active + passive |
| Nikto | Web server scanner | Comprehensive checks |

## SAST (Static Analysis)
| Tool | Languages | Integration |
|------|-----------|-------------|
| Semgrep | 30+ langs, custom rules | CLI, CI, pre-commit |
| SonarQube | 30+ langs | CI, PR decoration |
| CodeQL | 12+ langs | GitHub-native |
| Bandit | Python | CLI |
| gosec | Go | CLI, CI |
| Brakeman | Ruby on Rails | CLI |

## DAST (Dynamic Analysis)
| Tool | Type | Key Feature |
|------|------|-------------|
| OWASP ZAP | Web app scanner | Active + passive |
| Burp Suite | Proxy + scanner | Extensions |
| Nuclei | Template-based | CI-ready |
| Caido | Modern proxy | Lightweight Burp alternative |
| HTTPX | HTTP probe | Endpoint discovery |

## Dependency & Container Scanning
| Tool | Scope | CI Integration |
|------|-------|----------------|
| Trivy | Images, repos, K8s, IaC | `aquasecurity/trivy-action` |
| Grype | Images, filesystems | syft → grype pipeline |
| Snyk | OSS deps, containers, IaC | GitHub app, CLI |
| Dependabot | OSS deps (GitHub) | Auto-PR |
| Renovate | OSS deps (all platforms) | Auto-merge |

## Secrets Detection
| Tool | Pre-commit/CI |
|------|---------------|
| Gitleaks | `pre-commit` hook |
| TruffleHog | GitHub Action |
| git-secrets | `pre-commit` hook |
| detect-secrets | Yelp, pre-commit |

## Container & Orchestration Security
| Tool | Purpose | When |
|------|---------|------|
| docker-bench-security | CIS Docker benchmark | CI, periodic |
| Trivy | Image CVE scan | Every build |
| Falco | Runtime threat detection | Continuous |
| Kube-bench | CIS K8s benchmark | CI |
| Checkov | IaC (Docker, K8s, TF) | CI + pre-commit |
| OPA/Gatekeeper | K8s admission control | Every deploy |

## Authentication & Identity
| Technology | Use Case |
|------------|----------|
| bcrypt | Password hashing |
| Argon2 | Modern password hashing |
| OAuth2 + OIDC | Third-party login + identity |
| WebAuthn/Passkeys | Passwordless auth |
| TOTP | 2FA |

## Monitoring & API Security
- **Security Monitoring:** CrowdSec (IPS), Fail2ban (log-based ban), Wazuh (SIEM)
- **API Security:** OAuth2, rate limiting, input validation, encryption, audit logging
- **Rate limiting pattern:** `express-rate-limit` — 15 min window, 100 req/IP

## Security Checklist (Additional)
- [ ] Rate limiting on ALL auth endpoints
- [ ] CORS restricted to specific origin (not `*`)
- [ ] HSTS preload for domain
- [ ] CSP with nonce or hash for inline scripts
- [ ] Subresource Integrity (SRI) for CDN assets
- [ ] PostgreSQL row-level security for multi-tenant
- [ ] Secrets scanned in CI before merge
- [ ] Dependency audit runs weekly
- [ ] Session cookies: `HttpOnly`, `Secure`, `SameSite=Strict`
- [ ] File upload: validate MIME, limit size, scan with ClamAV
- [ ] Error pages: no stack traces, no version info
