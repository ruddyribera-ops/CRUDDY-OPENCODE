// D:\Users\Windows\.config\opencode\plugins\routing-stability.js
// OpenMythos spectral-radius-inspired routing stability metric.
// Detects oscillation (same agents dispatched in tight loop) and
// stagnation (repeated empty results) before the cost ceiling trips.
import { gateLog } from "./_shared.js"

const WINDOW_SIZE = 10
const OSCILLATION_MIN_RUN = 4
const STAGNATION_EMPTY_RUN = 3
const STAGNATION_EMPTY_THRESHOLD = 2

export const RoutingStability = async () => {
  const recent = []

  return {
    "tool.execute.after": async (input, output) => {
      if (input.tool !== "task") return

      const agent = input.tool_call?.subagent_type || "unknown"
      const result = output?.output ?? output?.result ?? ""
      const empty = String(result).trim().length === 0

      recent.push({ agent, ts: Date.now(), empty })
      if (recent.length > WINDOW_SIZE) recent.shift()

      const tail = recent.slice(-OSCILLATION_MIN_RUN).map(r => r.agent)
      const unique = new Set(tail)
      if (tail.length === OSCILLATION_MIN_RUN && unique.size <= 2) {
        gateLog("routing-stability", `OSCILLATION: ${tail.join("->")} (${unique.size} unique)`)
      }

      const lastN = recent.slice(-STAGNATION_EMPTY_RUN)
      const emptyCount = lastN.filter(r => r.empty).length
      if (lastN.length === STAGNATION_EMPTY_RUN && emptyCount >= STAGNATION_EMPTY_THRESHOLD) {
        gateLog("routing-stability", `STAGNATION: ${emptyCount}/${STAGNATION_EMPTY_RUN} empty`)
      }
    },
  }
}