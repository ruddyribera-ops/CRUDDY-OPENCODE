---
name: production-readiness
description: "Production readiness checklist — deploy, monitor, trace, track costs. Use when shipping to production, deploying a new feature, doing a release readiness review, or auditing an existing service for production fitness. Triggers: production ready, deploy check, ship it, release readiness, monitor this, cost audit, runtime safety, rollback plan."
triggers:
  - "production-readiness"
  - "production readiness"
  - "when to use production readiness"
  - "how to production readiness"
  - "production readiness examples"
  - "production readiness pattern"
applies_to:
  - "main-coordinator"
---


# Production Readiness

## When to Use This

Load this skill when:
- Preparing to deploy a new service or feature to production
- Conducting a release readiness review
- Auditing an existing deployed service for fitness
- Investigating production issues (runtime safety)
- Planning cost optimization for a running service

This skill composes **4 focused skills** into a single checklist: `deployment-patterns`, `tracing`, `cost-tracking`, and `no-silent-failure`.

---

## The 4 Lenses

### 1. Deployment Lens (`deployment-patterns/`)

Covers: Docker, docker-compose, Railway, containerization, environment configuration.

**Key questions:**
- Is the container image built correctly with multi-stage build?
- Are environment variables set correctly (no hardcoded secrets)?
- Does the service start and respond to health checks?
- Is the rollback plan documented?

### 2. Observability Lens (`tracing/`)

Covers: Distributed tracing, latency monitoring, error rate tracking, trace ID propagation.

**Key questions:**
- Does every request have a trace ID that flows through all hops?
- Are errors logged with trace context?
- Can you find the relevant traces for a given user complaint?
- Are latency percentiles (p50, p95, p99) tracked?

### 3. Cost Lens (`cost-tracking/`)

Covers: Token usage tracking, AI cost monitoring, infrastructure cost attribution.

**Key questions:**
- Do you know your cost per request / per user?
- Are there any anomalously expensive operations?
- Is caching in place where appropriate?
- Are unused resources being billed?

### 4. Reliability Lens (`no-silent-failure/`)

Covers: Error handling, never bare `except:pass`, structured logging with trace IDs.

**Key questions:**
- Does every `except` block log the error and re-raise (minimum)?
- Are errors logged with enough context to reproduce?
- Does the service degrade gracefully under partial failure?
- Are there circuit breakers for external dependencies?

---

## Composite Checklist

Run through this before any production deploy:

### Deployment
- [ ] Container image builds successfully with `docker build`
- [ ] No hardcoded secrets — all credentials from env vars or secret manager
- [ ] Health check endpoint returns 200 at `/health` or similar
- [ ] Graceful shutdown handling (SIGTERM support)
- [ ] Rollback plan documented (image tag, previous version)
- [ ] `README.md` updated with deployment instructions

### Observability
- [ ] Trace ID injected into every log line (request-scoped)
- [ ] Error logs include: trace ID, user ID (if applicable), timestamp, stack trace
- [ ] Latency tracked per endpoint with p50/p95/p99
- [ ] Error rate tracked per endpoint with alerting threshold
- [ ] Structured logging (JSON) for machine parsing

### Cost
- [ ] Token usage logged per AI API call (if applicable)
- [ ] Cost per request calculated or estimable
- [ ] Any new external API calls have rate limiting
- [ ] Unused dependencies removed from container image

### Reliability
- [ ] Every `except` block: logs error + re-raises (no bare `except:pass`)
- [ ] External service timeouts set (no infinite hangs)
- [ ] Circuit breaker pattern for external dependencies
- [ ] Feature flags for risky changes (enable gradually)
- [ ] Load testing done (or planned) for new endpoints

---

## Cross-References

Each focused skill adds specific value:

| Skill | What it adds |
|-------|-------------|
| `deployment-patterns/` | Container build, Railway deploy, environment config, health checks |
| `tracing/` | Trace ID propagation, latency monitoring, distributed tracing setup |
| `cost-tracking/` | Token usage tracking, AI cost attribution, infrastructure cost monitoring |
| `no-silent-failure/` | Error handling patterns, structured logging, circuit breakers |

---

## Quick Reference: Health-Check Snippet

PowerShell health-check you can run against a running service:

```powershell
# Basic production health check
$baseUrl = "https://your-service.com"
$traceId = [guid]::NewGuid().ToString()

# 1. Health endpoint
$health = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET
Write-Host "[$traceId] Health: $($health.StatusCode)"

# 2. Structured error check (search logs for trace ID)
# In your log aggregator: trace_id="$traceId" level=error

# 3. Latency check
$sw = [Diagnostics.Stopwatch]::StartNew()
$resp = Invoke-WebRequest -Uri "$baseUrl/api/your-endpoint" -Method GET
$sw.Stop()
Write-Host "[$traceId] Latency: $($sw.ElapsedMilliseconds)ms"

# 4. Cost spot-check (if AI-powered endpoint)
# Check your cost tracking dashboard for trace_id="$traceId"
```

---

## Red Flags (Block the Deploy)

These findings mean **do not deploy** until fixed:

1. Hardcoded credentials or API keys in code
2. No error handling (bare `except:pass` anywhere)
3. No health check endpoint
4. No trace ID in log output
5. No rollback plan documented
6. External calls with no timeout
7. New dependency with known high-severity CVE
