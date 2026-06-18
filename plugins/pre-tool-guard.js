// pre-tool-guard.js
// Plugin-based pre-tool enforcement (replaces scripts/hooks/pre-tool-check.ps1)
//
// Hooks: tool.execute.before
// Blocks: destructive commands, system file writes, git force pushes, hooks bypass,
//         secret key exposure, prompt injection, circumvention patterns
//
// Usage: OpenCode auto-loads this plugin via opencode.json plugin array.
// No manual wiring needed — runs on every tool call automatically.
//
// Research sources:
// - Steve Kinney "Making It Hard to Cheat the Guardrails" (Apr 2026)
// - secret-scan regex patterns (marcuspat/secretscan)
// - Soteri "How Secret Detection Tools Spot Leaks" (May 2025)
// - Dwarves Foundation security hooks

import path from "node:path"
import { existsSync, readFileSync, writeFileSync, appendFileSync } from "node:fs"
import { gateLog, GATE_LOG, CONFIG_ROOT } from "./_shared.js"

// Re-export gateLog with plugin name baked in (keeps existing call sites clean)
const log = (msg) => gateLog("pre-tool-guard", msg)

// ── Block patterns ──────────────────────────────────────────────────────────
const DESTRUCTIVE_PATTERNS = [
  /rm\s+-rf\s+\//,
  /rm\s+\//,
  /format-volume/i,
  /clear-disk/i,
  /dd\s+if=.*of=\/dev\//,
  /git\s+push\s+--force/i,
  /git\s+push\s+-f/i,
  /--force-push/i,
  /--no-verify/i
]

const FORBIDDEN_COMMANDS = [
  /DROP\s+TABLE/i,
  /DROP\s+DATABASE/i,
  /DELETE\s+FROM.*WHERE\s+1\s*=\s*1/i,
  /sudo\s+rm/i,
  /chmod\s+777/i
]

const SENSITIVE_PATTERNS = [
  /\.env$/i,
  /\.env\./i,
  /\.pem$/i,
  /\.key$/i,
  /\.pem\.key$/i,
  /id_rsa/i,
  /id_ed25519/i,
  /secrets\.yaml/i,
  /credentials\.json/i,
  /wallet\.json/i
]

const SYSTEM_DIR_PATTERNS = [
  /^\/etc\//,
  /^\/usr\/bin\//,
  /^\/usr\/sbin\//i,
  /^C:\\Windows\\/i,
  /^C:\\Program\s+Files\\/i
]

// ── Anti-Circumvention Patterns (Steve Kinney, Apr 2026) ──────────────────────
// Block skip flags and env vars that agents use to dodge verification hooks
// Plus argument injection patterns (Trail of Bits, Oct 2025 — RCE via flag injection)
const BYPASS_PATTERNS = [
  // Skip/bypass flags
  /(^|\s)(--no-verify)/i,
  /(^|\s)(HUSKY=0|LEFTHOOK=0|LEFTHOOK=false|LEFTHOOK_EXCLUDE=)/i,
  /(^|\s)(DISABLE_HOOKS|HOOKS_ENABLED=0)/i,
  // Git directory traversal to escape hooks
  /git\s+-C\s+[^\s]+(?:\s+(?:push|commit|merge|rebase))/i,
  // Find exec with rm/fmt/dangerous
  /find\s+[^\s]+\s+-exec\s+(?:rm|chmod|chown|dd|mount)/i,
  // Option splitting (rm -r -f vs rm -rf)
  /(?:^|\s)rm\s+-[rRf]+(?:\s+[^-])/,
  // Force push variants
  /git\s+(?:push|merge)\s+--force/i,
  /git\s+(?:push|merge)\s+-f\b/i,
  /--force-push/i,
  // Editing hook files to weaken checks
  /lefthook\.yml|\.husky\/[^\s]+|package\.json.*script.*hook/i,
  // ── Argument Injection (Trail of Bits, Oct 2025) ──────────────────────────
  // Benign command + malicious flag = RCE despite allow-listing
  // go test -exec, python -c, node -e — inject secondary execution
  /(?:^|\s)(?:go\s+test|go\s+run).*-(?:exec|runextra)/i,
  /(?:^|\s)python\s+-[cm]\s+['"`]/i,
  /(?:^|\s)node\s+-(?:eval|exec|r|inpe?)\s+['"`]/i,
  /(?:^|\s)perl\s+-e\s+['"`]/i,
  /(?:^|\s)ruby\s+-e\s+['"`]/i,
  /(?:^|\s)php\s+-[r]\s+['"`]/i,
  /(?:^|\s)bash\s+-c\s+['"`]/i,
  /(?:^|\s)sh\s+-c\s+['"`]/i,
  /(?:^|\s)cmd\s+\/c\s+['"`]/i,
  /(?:^|\s)powershell\s+-enc/i,
  // exec/popen/shellspawn with user-controlled args
  /\bexec\s*\(\s*\$/i,
  /(?:^|\s)\$\([^)]+\)/i,  // command substitution
  /(?:^|\s)`[^`]+`/i,      // backtick substitution
]

// ── Secret Detection Patterns ──────────────────────────────────────────────────
// Based on secret-scan (marcuspat) + Soteri (May 2025) + mazen160/secrets-patterns-db (1600+ patterns)
const SECRET_PATTERNS = [
  // AWS Access Key ID — all variants: AKIA, AGPA, AROA, AIPA, ANPA, ANVA, ASIA, ABIA, ACCA
  // Extended from mazen160/rules-stable.yml (AWS pattern, high confidence)
  /\b(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA|ABIA|ACCA)[A-Z0-9]{16}\b/i,
  // AWS Secret Access Key — 40 char base64
  /(?<![A-Z0-9])[A-Za-z0-9\/+=]{40}(?![A-Z0-9])/,
  // GitHub Personal Access Token — ghp_ 36 chars
  /ghp_[A-Za-z0-9_]{36}/i,
  // GitHub OAuth / other tokens — gho_, ghu_, ghs_, ghr_
  /gh[ousr]_[A-Za-z0-9_]{36,40}/i,
  // Slack tokens — xox[baprs]-10-48 chars
  /xox[baprs]-[0-9A-Za-z-]{10,48}/i,
  // Stripe keys — sk_live_ 24+ chars
  /sk_live_[0-9a-zA-Z]{24,}/i,
  // Google API key — AIza prefix, 35 chars
  /AIza[0-9A-Za-z\-_]{35}/i,
  // Anthropic API key — sk-ant- prefix, 48+ chars
  /sk-ant-[a-zA-Z0-9]{48,}/i,
  // OpenAI key — sk- 48+ chars
  /sk-[A-Za-z0-9]{48,}/i,
  // JWT tokens — 3 dot-separated base64url chunks
  /[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_+/=]*/,
  // PEM private key headers (from mazen160 Asymmetric Private Key pattern, high confidence)
  /-----BEGIN\s+((EC|PGP|DSA|RSA|OPENSSH)\s+)?PRIVATE\s+KEY( BLOCK)?-----/i,
  // Generic high-entropy secret (Shannon >4.5 in context)
  /[A-Za-z0-9\/+=]{32,}/,
]

// ── Injection Detection Patterns ──────────────────────────────────────────────
// Hidden instructions in output (HTML comments, encoded strings, etc.)
const INJECTION_PATTERNS = [
  // HTML comment injection attempts
  /<!--[\s\S]*?(--!>|-->|<![-\s\S]*?>)/,
  // Unicode/encoding trickery
  /\u200b|\u200c|\u200d|%E2%80%8B|%E2%80%8C|%E2%80%8D/i,
  // Common prompt injection markers
  /(?:ignore\s+(?:previous|above|all)\s+(?:instructions?|rules?|directives))/i,
  /(?:disregard\s+(?:previous|above|all))/i,
  /(?:you\s+(?:are\s+)?(?:now\s+)?(?:free\s+to|allowed\s+to))\s+(?:ignore|bypass|skip)/i,
  // System prompt extraction attempts
  /(?:extract\s+(?:system\s+)?prompt|from\s+(?:system\s+)?instruction)/i,
  // Role play / jailbreak prefixes
  /^(?:system|assistant|user):/i,
  // Base64 encoded command injection
  /base64\s+-[d]\s+[A-Za-z0-9+/=]{20,}/i,
]

// ── Pattern cache (compile once at module load) ────────────────────────────────
// These arrays are top-level consts, so regex compilation happens exactly once
// when this module is first imported by OpenCode. Each `.test()` call below
// reuses the compiled regex object — no recompilation per tool execution.
const PATTERN_CACHE_VERSION = "1.0"
let patternCacheWarmed = false

function warmPatternCache() {
  if (patternCacheWarmed) return
  patternCacheWarmed = true
  const total = DESTRUCTIVE_PATTERNS.length + FORBIDDEN_COMMANDS.length +
                SENSITIVE_PATTERNS.length + SYSTEM_DIR_PATTERNS.length +
                BYPASS_PATTERNS.length + SECRET_PATTERNS.length + INJECTION_PATTERNS.length
  // Fire-and-forget: log once via shared gateLog to prove cache is active.
  // We don't gate startup on this — it must not slow plugin init.
  setImmediate(() => {
    log(`pattern cache v${PATTERN_CACHE_VERSION} warmed: ${total} patterns across 7 categories`)
  })
}
warmPatternCache()  // fire at module load

// ── Check functions ───────────────────────────────────────────────────────────
function isBlockedDestructive(command) {
  return DESTRUCTIVE_PATTERNS.some(p => p.test(command))
}

function isForbiddenCommand(command) {
  return FORBIDDEN_COMMANDS.some(p => p.test(command))
}

function isSensitiveFile(filepath) {
  return SENSITIVE_PATTERNS.some(p => p.test(filepath))
}

function isSystemDir(filepath) {
  return SYSTEM_DIR_PATTERNS.some(p => p.test(filepath))
}

// ── Anti-circumvention check (Steve Kinney) ────────────────────────────────────
function isBypassAttempt(command) {
  return BYPASS_PATTERNS.some(p => p.test(command))
}

// ── Secret exposure check (secret-scan + Soteri) ───────────────────────────────
function containsSecret(text) {
  return SECRET_PATTERNS.some(p => p.test(text))
}

// ── Injection detection check ──────────────────────────────────────────────────
function isInjectionAttempt(text) {
  return INJECTION_PATTERNS.some(p => p.test(text))
}

// ── Single-pass guard runner ──────────────────────────────────────────────────
// Tests text against multiple pattern categories in a single pass with early
// exit on first match. More efficient than calling 4-5 separate isX() functions
// when checking the same input. Used for the "check everything" path.
const GUARD_CATEGORIES = {
  bypass: BYPASS_PATTERNS,
  destructive: DESTRUCTIVE_PATTERNS,
  forbidden: FORBIDDEN_COMMANDS,
  secret: SECRET_PATTERNS,
  injection: INJECTION_PATTERNS,
}

function runAllGuards(text, categories) {
  for (const cat of categories) {
    const patterns = GUARD_CATEGORIES[cat]
    if (!patterns) continue
    for (const p of patterns) {
      if (p.test(text)) {
        return { matched: true, category: cat, pattern: p.source.slice(0, 60) }
      }
    }
  }
  return { matched: false }
}

// ── Tool-call density governor ────────────────────────────────────────────────
// Tracks tool-call rate per session. If >8 calls/min with no checkpoint progress,
// forces a reflection checkpoint. Prevents M2.7 sub-agents from spinning on
// Read/Search/Grep loops without producing output.
const DENSITY_LOG = path.join(CONFIG_ROOT, "memory", "tool-density.jsonl")
const DENSITY_WINDOW_MS = 60000  // 1 minute
const DENSITY_THRESHOLD = 8      // max calls/min before warning
const CHECKPOINT_PATTERNS = ["/am-result", "/pm-result", "/brief.md", "DONE.flag", "-result.md"]

const densityState = new Map()  // sessionId → { calls: [], lastCheckpoint: number }

function getSessionId(input) {
  return input.session?.id || input.sessionID || "unknown"
}

function hasCheckpointProgress(args) {
  const path = args.path || args.filePath || args.command || ""
  return CHECKPOINT_PATTERNS.some(p => path.includes(p))
}

function readDensityState(sessionId) {
  try {
    if (!existsSync(DENSITY_LOG)) return { calls: [], lastCheckpoint: 0 }
    const lines = readFileSync(DENSITY_LOG, "utf8").split("\n").filter(l => l.trim())
    const relevant = lines.filter(l => {
      try {
        const entry = JSON.parse(l)
        return entry.sessionId === sessionId && (Date.now() - entry.ts) < DENSITY_WINDOW_MS
      } catch { return false }
    })
    const calls = relevant.map(l => JSON.parse(l))
    const lastCheckpoint = calls.filter(c => c.checkpoint).length
    return { calls, lastCheckpoint }
  } catch {
    return { calls: [], lastCheckpoint: 0 }
  }
}

function logDensityEvent(sessionId, tool, args) {
  try {
    const entry = {
      ts: Date.now(),
      sessionId,
      tool,
      checkpoint: hasCheckpointProgress(args)
    }
    appendFileSync(DENSITY_LOG, JSON.stringify(entry) + "\n")
  } catch {}
}

function cleanOldDensityEntries() {
  try {
    if (!existsSync(DENSITY_LOG)) return
    const lines = readFileSync(DENSITY_LOG, "utf8").split("\n").filter(l => l.trim())
    const recent = lines.filter(l => {
      try {
        const entry = JSON.parse(l)
        return (Date.now() - entry.ts) < DENSITY_WINDOW_MS * 2
      } catch { return false }
    })
    writeFileSync(DENSITY_LOG, recent.join("\n") + "\n")
  } catch {}
}

// ── Main guard ────────────────────────────────────────────────────────────────
export const PreToolGuard = async () => {
  // Prune old entries once at startup
  cleanOldDensityEntries()

  return {
    "tool.execute.before": async (input, output) => {
      const { tool } = input
      const args = input.args || {}
      const sessionId = getSessionId(input)

      // ── Tool-call density governor ──────────────────────────────────────────
      if (tool !== "question") {  // question tool doesn't count
        const { calls } = readDensityState(sessionId)
        const now = Date.now()
        const recentCalls = calls.filter(c => (now - c.ts) < DENSITY_WINDOW_MS)
        logDensityEvent(sessionId, tool, args)

        // Warn if density is too high with no checkpoint progress
        if (recentCalls.length >= DENSITY_THRESHOLD) {
          const checkpoints = recentCalls.filter(c => c.checkpoint).length
          if (checkpoints === 0) {
            const msg = `TOOL DENSITY WARNING: ${recentCalls.length} calls in ${DENSITY_WINDOW_MS/1000}s with no checkpoint. Consider stopping to report partial results.`
            log(msg)
            // Also write a flag the sub-agent can check
            const flagFile = path.join(CONFIG_ROOT, "gates", ".density-warning")
            try {
              writeFileSync(flagFile, `${sessionId}|${now}|${recentCalls.length}\n`)
            } catch {}
          }
        }
      }

      // Only check bash and file-modifying tools for the security patterns
      if (!["Bash", "Write", "Edit"].includes(tool)) return

      const command = args.command || args.path || args.filePath || ""
      const filePath = args.path || args.filePath || ""
      const fullText = command || filePath

      // Check: anti-circumvention (Steve Kinney — block skip flags, git -C, find -exec, etc.)
      if (tool === "Bash" && command) {
        if (isBypassAttempt(command)) {
          const msg = `BLOCKED: bypass/cicumvention pattern detected: ${command.slice(0, 80)}`
          log(msg)
          throw new Error(msg)
        }
      }

      // Check: secret exposure in command args or file content
      if (fullText && containsSecret(fullText)) {
        const msg = `BLOCKED: secret/key pattern detected in command or path`
        log(msg)
        throw new Error(msg)
      }

      // Check: bash destructive commands
      if (tool === "Bash" && command) {
        if (isBlockedDestructive(command)) {
          const msg = `BLOCKED: destructive command: ${command.slice(0, 80)}`
          log(msg)
          throw new Error(msg)
        }
        if (isForbiddenCommand(command)) {
          const msg = `BLOCKED: forbidden command: ${command.slice(0, 80)}`
          log(msg)
          throw new Error(msg)
        }
        if (/git.*--force/i.test(command)) {
          const msg = "BLOCKED: git --force detected. Use --force-with-lease instead."
          log(msg)
          throw new Error(msg)
        }
        if (/--no-verify/i.test(command)) {
          const msg = "BLOCKED: hooks bypass (--no-verify) not allowed."
          log(msg)
          throw new Error(msg)
        }
      }

      // Check: sensitive file writes
      if ((tool === "Write" || tool === "Edit") && filePath) {
        if (isSensitiveFile(filePath)) {
          const msg = `BLOCKED: write to sensitive file: ${filePath}`
          log(msg)
          throw new Error(msg)
        }
        if (isSystemDir(filePath)) {
          const msg = `BLOCKED: system directory write: ${filePath}`
          log(msg)
          throw new Error(msg)
        }
      }
    }
  }
}