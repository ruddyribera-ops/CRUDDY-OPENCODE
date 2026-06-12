# /deepwork — Background orchestrator
# Turns a big goal into a file-backed plan with bead workers.
# Usage: /deepwork "Add OAuth login" [D:\proj]

Run deepwork.ps1 from the scripts directory, passing the goal and optional project dir.

Script: `$CONFIG/scripts/deepwork.ps1`
Arguments: `-Goal "<goal>" [-ProjectDir "<path>"]`

Example:
```
/deepwork Add user authentication with JWT
/deepwork Refactor the auth module D:\ACTIVE PROJECTS\PRIA v10
```

The script creates:
- A plan file in `.opencode/deepwork/<plan-id>.plan.md`
- A beads directory in `.opencode/deepwork/<plan-id>.beads/`
- A COORDINATOR.md with decomposition instructions

After creation, use `deepwork-status.ps1 -PlanId <id> [-ProjectDir '<path>'] [-Watch]` to track progress.

Steps:
1. Run deepwork.ps1 with the goal
2. Review the generated plan and COORDINATOR.md
3. Spawn workers as beads
4. Poll with deepwork-status.ps1