# Chrome DevTools MCP — Usage Guide

## Quick Start

### 1. Launch Chrome with Remote Debugging

**Option A — Windows Shortcut:**
```
chrome.exe --remote-debugging-port=9222
```

**Option B — PowerShell:**
```powershell
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList "--remote-debugging-port=9222"
```

**Option C — Add to system PATH permanently:**
Create a shortcut or use where chrome to find the path, then alias it.

### 2. Start OpenCode

The chrome-devtools MCP server will auto-connect to Chrome on port 9222.

## Available Tools

Once connected, you have access to:

| Tool | What It Does |
|------|-------------|
| `chrome_navigate` | Navigate to URL or open new tab |
| `chrome_screenshot` | Full page or viewport screenshot |
| `chrome_snapshot` | Capture DOM snapshot (accessibility tree) |
| `chrome_console_messages` | Read console logs |
| `chrome_query_selector` | Query DOM with CSS selector |
| `chrome_evaluate` | Execute JavaScript in page context |
| `chrome_get_cookies` | Read cookies for domain |
| `chrome_network_events` | Monitor network requests/responses |
| `chrome_tabs_list` | List open tabs |
| `chrome_tab_navigate` | Navigate specific tab |

## Use Cases

### E2E Testing (Local)
```
Agent can:
1. Navigate to localhost:3000
2. Take screenshot to verify UI
3. Query DOM to check element exists
4. Read console for JS errors
5. Execute JS to trigger interactions
```

### Debug Production Issues
```
Agent can:
1. Connect to Chrome running production app
2. Inspect live DOM state
3. Read console errors
4. Execute JS to test hypotheses
5. Capture screenshot of bug
```

## Troubleshooting

### "Chrome not found" or "Cannot connect"
```bash
# Verify Chrome is running with debug port
curl http://localhost:9222/json/version

# Should return Chrome version info
```

### "Port already in use"
```bash
# Find what's using port 9222
netstat -ano | findstr :9222

# Kill it or use different port
chrome --remote-debugging-port=9223
```

### "Auto-connect failed"
The MCP needs Chrome 144+ for autoConnect. If your Chrome is older:
```bash
# Manual connection
npx -y chrome-devtools-mcp --browserUrl http://127.0.0.1:9222
```

## Security Notes

- Remote debugging gives FULL control of Chrome
- Only enable on local machine, not exposed to network
- Close Chrome and restart normally when done
- No API keys needed — local only