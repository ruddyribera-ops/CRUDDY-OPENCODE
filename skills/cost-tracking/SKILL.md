---
name: cost-tracking
description: LLM cost attribution and FinOps — per-model pricing, per-span token tracking, caching strategies, rate limiting, cost anomaly detection. Use when tracking AI spend, optimizing costs, or detecting cost anomalies. Triggers: cost, token, FinOps, spend, pricing, cache, rate limit, per-user cost, per-feature cost.
---

# Cost Tracking Skill — LLM FinOps

Distributed tracing is the practice of tracking a request as it flows through multiple agents, sub-tasks, and tool calls. It is essential for debugging failures in multi-step AI workflows where a user request spawns dozens of sub-agent dispatches.

## Per-Model Pricing Tables

### Anthropic Models

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context Window |
|-------|----------------------|------------------------|----------------|
| haiku | $0.25 | $1.25 | 200K |
| sonnet | $3.00 | $15.00 | 200K |
| opus | $15.00 | $75.00 | 200K |

**Note:** Prices are for June 2026. Check [Anthropic pricing page](https://docs.anthropic.com/en/docs billing) for current rates.

### OpenAI Models

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context Window |
|-------|----------------------|------------------------|----------------|
| gpt-4o-mini | $0.15 | $0.60 | 128K |
| gpt-4o | $2.50 | $10.00 | 128K |
| gpt-4o-turbo | $5.00 | $15.00 | 128K |

### Cost Calculation Formula

```
total_cost = (tokens_in × input_price) + (tokens_out × output_price)
```

For a haiku call with 10K input tokens and 5K output tokens:
```
cost = (10,000 / 1,000,000 × $0.25) + (5,000 / 1,000,000 × $1.25)
cost = $0.0025 + $0.00625 = $0.00875
```

---

## Token Attribution

Every span should record token usage when an LLM call is made:

```javascript
span = {
  trace_id: "abc123",
  span_id: "span456",
  name: "code-builder.implement",
  tags: {
    model: "haiku",
    tokens_in: 12000,
    tokens_out: 3400,
    cost_usd: 0.00875  // computed from pricing table
  }
}
```

### Input vs Output Tokens

- **Input tokens:** prompt, system message, conversation history
- **Output tokens:** generated response
- **Cached tokens:** some providers (OpenAI, Anthropic) charge less for cached hits

```javascript
// Per-call breakdown
{
  tokens_in: 12000,
  tokens_out: 3400,
  cached_tokens_in: 8000,  // from context cache
  cost_usd: 0.0025  // $0.25/M × 10K uncached input
}
```

---

## Helicone-Style Caching

Request caching can reduce costs by 80-95% for repeated or similar prompts.

### Cache Hit Patterns

| Pattern | Cache Hit Rate | Implementation |
|---------|---------------|----------------|
| Exact duplicate requests | 95%+ | Hash the prompt, store result |
| Semantic duplicates | 70-85% | Embedding similarity >0.95 |
| System prompt reuse | 100% for system portion | Separate system context caching |

### Cache Strategy

```
1. Hash the full prompt (SHA-256)
2. Check cache store for existing entry
3. If hit: return cached response, log cache_hit=true
4. If miss: call LLM, store response, log cache_hit=false
```

### Cache Key Components

```javascript
cacheKey = {
  prompt_hash: sha256(fullPrompt),
  model: modelName,
  temperature: temperature,
  max_tokens: maxTokens
}
```

**Note:** Cache effectiveness depends on prompt structure. Structured, repeatable prompts (like code generation) hit more than conversational prompts.

---

## Rate Limiting Patterns

### Types of Rate Limits

| Limit Type | Scope | Typical Value |
|------------|-------|---------------|
| Requests per minute | Per-user | 60-100 |
| Tokens per minute | Per-user | 50K-150K |
| Requests per day | Per-team | 10K-50K |
| Total monthly spend | Global | $500-$10K |

### Rate Limit Headers

```javascript
// OpenAI-style headers
{
  "x-ratelimit-limit-requests": 100,
  "x-ratelimit-remaining-requests": 42,
  "x-ratelimit-reset-requests": "30s",
  "x-ratelimit-limit-tokens": 150000,
  "x-ratelimit-remaining-tokens": 125000,
  "x-ratelimit-reset-tokens": "1m"
}
```

### Per-User Rate Limiting

```javascript
class RateLimiter {
  constructor() {
    this.users = new Map()  // userId -> { tokens: number, resetAt: Date }
  }

  checkLimit(userId, tokensNeeded) {
    const user = this.users.get(userId)
    if (!user) return true

    if (Date.now() > user.resetAt) {
      // Reset window
      user.tokens = 0
      user.resetAt = Date.now() + 60000
    }

    return (user.tokens + tokensNeeded) <= 150000
  }

  record(userId, tokensUsed) {
    const user = this.users.get(userId) || { tokens: 0, resetAt: Date.now() + 60000 }
    user.tokens += tokensUsed
    this.users.set(userId, user)
  }
}
```

---

## Cost Anomaly Detection

### Baseline Calculation

```javascript
// Rolling 7-day baseline
baseline = {
  daily_avg_cost: sum(last_7_days_costs) / 7,
  daily_std_dev: stddev(last_7_days_costs),
  hourly_avg: per-hour breakdown of baseline
}
```

### Anomaly Thresholds

| Level | Threshold | Action |
|-------|-----------|--------|
| Warning | 2x baseline | Log, continue monitoring |
| Alert | 3x baseline | Page on-call |
| Critical | 5x baseline | Immediate response required |

### Detection Patterns

**Sudden Spike:**
```
cost_last_hour >> baseline + (3 × stddev)
→ Someone switched models / something is in a loop
```

**Slow Burn:**
```
cost_increasing_5%_per_day for 7 days
→ Gradual regression, not acute — investigate trend
```

### Alert Example

```javascript
{
  alert: "cost_anomaly",
  severity: "warning",  // or "critical"
  current_cost: 127.50,
  baseline_cost: 42.00,
  ratio: 3.04,  // 3x baseline
  window: "last_hour",
  likely_cause: "model_switch or loop",
  action: "investigate spans in coordination-log"
}
```

---

## Burn Rate Forecasting

### Days Until Budget Exhaustion

```javascript
function forecastExhaustion(currentSpend, dailyBudget, daysRemaining) {
  dailyBurnRate = currentSpend / daysElapsed
  daysRemaining = dailyBudget / dailyBurnRate
  exhaustionDate = Date.now() + (daysRemaining × 24 × 60 × 60 × 1000)

  return {
    dailyBurnRate,
    daysRemaining: Math.floor(daysRemaining),
    exhaustionDate
  }
}
```

### Example

```
Current spend: $350
Daily budget: $500
Days elapsed: 5

dailyBurnRate = $350 / 5 = $70/day
daysRemaining = $500 / $70 = 7.1 days
exhaustionDate = today + 7 days
```

---

## Per-Feature Cost Attribution

Track cost at the feature level using span tags:

```javascript
// Every span should have feature attribution
span = {
  name: "code-builder.implement",
  tags: {
    feature: "user-auth",      // which feature
    module: "login",           // which module
    cost_usd: 0.0234
  }
}
```

### Aggregation Query

```bash
# Aggregate cost by feature from coordination log
cat ~/.config/opencode/memory/coordination-log.jsonl \
  | jq 'select(.event == "agent_dispatch" and .cost_usd != null)' \
  | jq -r '.feature + "\t" + .cost_usd' \
  | awk '{sum[$1] += $2} END {for (f in sum) print f "\t" sum[f]}' \
  | sort -k2 -rn
```

---

## Cost Optimization Recommendations

| Pattern | Savings | Implementation |
|---------|---------|---------------|
| Use haiku for simple tasks | 10-20x vs sonnet | Route haiku/sonnet by complexity |
| Enable prompt caching | 80-95% on repeated | Cache system context |
| Batch similar requests | 30-50% | Queue and batch LLM calls |
| Reduce max_tokens | 10-30% | Set exact max, not generous cap |
| Truncate long history | 15-40% | Keep only relevant context |

---

## Relationship to Other Skills

- **`tracing`**: Token attribution is recorded at the span level — spans should include `tokens_in`, `tokens_out`, and `cost_usd`
- **`performance-optimization`**: Latency and cost are often correlated — slow spans cost more
- **`karpathy-guidelines`**: "Simplicity first" applies to model choice — don't use sonnet when haiku suffices
