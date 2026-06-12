// graph-write-task.js
// Helper: writes a task node + edge to graph memory
// Usage: node graph-write-task.js <taskName> <agent> <sessionName> <graphScriptPath>

const fs = require("fs");
const { execFileSync } = require("child_process");

const [taskName, agent, sessionName, graphPath] = process.argv.slice(2);

if (!taskName || !agent || !graphPath) {
  console.error("Usage: node graph-write-task.js <taskName> <agent> <sessionName> <graphPath>");
  process.exit(1);
}

const ts = new Date().toISOString();
const data = JSON.stringify({ task: taskName, agent, ts });

try {
  const out = execFileSync("node", [graphPath, "create-node", "task", "--name", `Task-${taskName}`, "--data", data])
    .toString().trim();
  console.log("NODE:", out);

  if (sessionName && sessionName !== "unknown") {
    const edgeOut = execFileSync("node", [
      graphPath, "create-edge",
      "--from", `Session-${sessionName}`,
      "--to", `Task-${taskName}`,
      "--relationship", "completes"
    ]).toString().trim();
    console.log("EDGE:", edgeOut);
  }
} catch (e) {
  console.error("ERR:", e.message.slice(0, 300));
  process.exit(1);
}
