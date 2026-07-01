# Plugin Moved

This plugin has been moved to ../scripts/gate/integration-test.mjs.

Reason: The file ran main() at module load without an export const guard, causing it to execute on every OpenCode startup and corrupt the task counter.

**Original file location:** ~/.config/opencode/plugins/integration-test.js
**New location:** ~/.config/opencode/scripts/gate/integration-test.mjs

To run manually: 
ode ../scripts/gate/integration-test.mjs

