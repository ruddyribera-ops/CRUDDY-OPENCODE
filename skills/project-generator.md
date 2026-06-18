# project-generator

Auto-invokes 6-agent dev team for new project creation

## Auto-Triggers On

User asks: `create`, `build`, `new project`, `scaffold`, `nueva app`, `quiero crear`, `desde cero`

## What Happens

1. User: "create a real-time chat API"
2. OpenCode detects project-creation intent
3. Automatically invokes: `opencode-build "create a real-time chat API" "auto"`
4. Returns complete project orchestration in seconds

## Output

```json
{
  "status": "COMPLETE",
  "spec": "Project specification with user stories and acceptance criteria",
  "backend": "Backend implementation plan",
  "frontend": "Frontend implementation plan",
  "tests": "Test coverage requirements",
  "deployment": "Deployment strategy and rollback plan"
}
```

## How It Works

- **Phase 1:** PM creates specification
- **Phase 2:** Backend + Frontend implement in parallel
- **Phase 3:** QA validates tests
- **Phase 4:** DevOps prepares deployment

All 6 agents orchestrate automatically. No manual commands needed.
