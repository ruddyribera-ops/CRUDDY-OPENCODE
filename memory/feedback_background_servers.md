---
name: Background server processes in PowerShell - permanent solution
description: |
  PROBLEM: Start-Process -NoNewWindow with php artisan serve blocks the shell tool. 
  The shell waits for stdout/stderr that never comes cleanly, hanging the session.
  
  SOLUTION: Redirect output to NUL (Windows black hole) to detach the process.
  The `-WindowStyle Hidden` and redirecting stdout/stderr to $null makes the process
  truly background — the shell tool returns immediately.
  
  NEVER: `Start-Process php artisan serve` without redirect — blocks forever.
  NEVER: `php artisan serve > /dev/null 2>&1 &` — bash background, not PowerShell.
  
  ALWAYS for PHP/Laravel servers:
    Start-Process -NoNewWindow -WindowStyle Hidden php -ArgumentList "artisan","serve","--port=XXXX" -RedirectStandardOutput NUL -RedirectStandardError NUL
    
  For Node/Express servers:
    Start-Process -NoNewWindow -WindowStyle Hidden node -ArgumentList "server.js","--port=XXXX" -RedirectStandardOutput NUL -RedirectStandardError NUL
    
  The key insight: `-RedirectStandardOutput NUL -RedirectStandardError NUL` detaches
  stdout/stderr so the process is fully backgrounded.
  
  Alternative: Use `Start-Process -PassThru` to get the PID immediately, which also works.
type: feedback
---

# Background Server Processes in PowerShell — Permanent Solution

## The Problem

When you run `Start-Process -NoNewWindow php artisan serve`, the shell tool blocks because PowerShell's `Start-Process` waits for stdout/stderr handles to be available. If the process never closes those handles (a long-running server), the shell tool hangs.

## The Permanent Solution

Always redirect stdout and stderr to NUL when starting background servers:

```powershell
# ✅ CORRECT — truly background, returns immediately
Start-Process -NoNewWindow -WindowStyle Hidden php -ArgumentList "artisan","serve","--port=8080" -RedirectStandardOutput NUL -RedirectStandardError NUL

# For Node.js servers
Start-Process -NoNewWindow -WindowStyle Hidden node -ArgumentList "server.js","--port=3000" -RedirectStandardOutput NUL -RedirectStandardError NUL
```

## Why NUL Works

Windows has a special device `NUL` that swallows all output. By redirecting both stdout and stderr to NUL, the process's output handles are fully detached from the calling shell — the shell returns immediately and the process runs truly in the background.

## How to Apply This

1. **Before starting any background server**, always add `-RedirectStandardOutput NUL -RedirectStandardError NUL`
2. **For the OpenCode coordinator and all agents**, this pattern should be automatic when starting servers
3. **Verification**: After starting, wait 3 seconds then `Invoke-WebRequest http://127.0.0.1:PORT -UseBasicParsing` to confirm it's up

## Stopping Background Servers

```powershell
# Find by port
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ -Force }

# Kill by name
Get-Process -Name php -ErrorAction SilentlyContinue | Stop-Process -Force

# Kill on specific port (preferred)
Stop-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess -Force -ErrorAction SilentlyContinue
```

## For the Coordinator (main-coordinator.md)

This pattern should be in the coordinator's permanent workflow. When any agent needs to start a server, the coordinator should enforce:

```
Before: Start-Process php artisan serve --port=8080
After:  Start-Process -NoNewWindow -WindowStyle Hidden php -ArgumentList "artisan","serve","--port=8080" -RedirectStandardOutput NUL -RedirectStandardError NUL
```

## Why This Matters

- Without this: the coordinator hangs and can't do anything until the server dies
- With this: server runs, coordinator continues, verification via HTTP confirms it's up
- Prevents: broken sessions, lost context, inability to test changes

## Other Background Patterns

```powershell
# Python Flask/FastAPI
Start-Process -NoNewWindow -WindowStyle Hidden python -ArgumentList "-m","flask","run","--port=5000" -RedirectStandardOutput NUL -RedirectStandardError NUL

# Go servers
Start-Process -NoNewWindow -WindowStyle Hidden go -ArgumentList "run","server.go" -RedirectStandardOutput NUL -RedirectStandardError NUL

# Any long-running Node process
Start-Process -NoNewWindow -WindowStyle Hidden node -ArgumentList "index.js" -RedirectStandardOutput NUL -RedirectStandardError NUL
```