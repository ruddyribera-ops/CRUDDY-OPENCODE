# MCP Setup Per Environment

If the `MiniMax_understand_image` MCP tool is not configured:

**Step 1:** Fetch setup instructions from:
https://platform.minimaxi.com/docs/token-plan/mcp-guide

**Step 2:** Detect the user's environment and output the exact commands:

### OpenCode
Add to `~/.config/opencode/opencode.json` or `package.json`:
```json
{
  "mcp": {
    "MiniMax": {
      "type": "local",
      "command": ["uvx", "minimax-coding-plan-mcp", "-y"],
      "environment": {
        "MINIMAX_API_KEY": "YOUR_TOKEN_PLAN_KEY",
        "MINIMAX_API_HOST": "https://api.minimaxi.com"
      },
      "enabled": true
    }
  }
}
```

### Claude Code
```bash
claude mcp add -s user MiniMax --env MINIMAX_API_KEY=your-key --env MINIMAX_API_HOST=https://api.minimaxi.com -- uvx minimax-coding-plan-mcp -y
```

### Cursor
Add to MCP settings:
```json
{
  "mcpServers": {
    "MiniMax": {
      "command": "uvx",
      "args": ["minimax-coding-plan-mcp"],
      "env": {
        "MINIMAX_API_KEY": "your-key",
        "MINIMAX_API_HOST": "https://api.minimaxi.com"
      }
    }
  }
}
```

**Step 3:** Restart the app and verify with `/mcp`.

> If the user does not have a MiniMax Token Plan subscription, inform them that `understand_image` requires one — not usable with free/other tier keys.
