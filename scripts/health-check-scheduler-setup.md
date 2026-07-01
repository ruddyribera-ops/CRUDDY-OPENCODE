# Periodic Health Check — Windows Task Scheduler Setup

`checkpoint-health.ps1` needs to run every 30 minutes (recommended) to detect
silent failures and self-heal before they compound into session loss.

---

## Option A — PowerShell One-Liner (fastest)

Run this in an **elevated PowerShell** terminal:

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "~/.config/opencode\scripts\checkpoint-health.ps1" -Digest'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration ([TimeSpan]::MaxValue)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
Register-ScheduledTask -TaskName 'OpenCode Health Check' -Action $action -Trigger $trigger -Settings $settings -Description 'OpenCode checkpoint/session health monitor — runs every 30 min' -Force
```

Verify it registered:

```powershell
Get-ScheduledTask -TaskName 'OpenCode Health Check' | Get-ScheduledTaskInfo
```

---

## Option B — Task Scheduler GUI

1. Open **Task Scheduler** (`taskschd.msc`)
2. Right-click **Task Scheduler Library → Create Task**
3. **General** tab:
   - Name: `OpenCode Health Check`
   - Run whether user is logged on or not *(check this if you want it to run without a session)*
   - Run with highest privileges
4. **Triggers** tab → New:
   - Begin the task: `On a schedule`
   - Repeat every **30 minutes**, for a duration of **indefinitely**
5. **Actions** tab → New:
   - Program: `powershell.exe`
   - Arguments: `-NoProfile -ExecutionPolicy Bypass -File "~/.config/opencode\scripts\checkpoint-health.ps1" -Digest`
6. **Settings** tab:
   - Allow task to run on demand
   - If the task fails, restart every minute, up to 3 retries
   - Stop the task if it runs longer than 5 minutes
7. Click **OK** — enter credentials if prompted

---

## Option C — Automated Setup Script

Run this once to install the scheduled task (includes the digest output and
a daily summary at 09:00):

```powershell
# --- paste into an elevated PowerShell prompt ---
$scriptPath = "~/.config/opencode\scripts\checkpoint-health.ps1"
$digestDir  = "~/.config/opencode\memory"

# 30-minute health check
$action30 = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Digest"
$trig30   = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration ([TimeSpan]::MaxValue)
$sett30   = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask 'OpenCode Health Check' -Action $action30 -Trigger $trig30 -Settings $sett30 -Description 'OpenCode checkpoint/session health monitor — every 30 min' -Force

# Daily digest at 09:00
$actionDaily = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Digest"
$trigDaily   = New-ScheduledTaskTrigger -Daily -At '09:00'
$settDaily   = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask 'OpenCode Daily Health Digest' -Action $actionDaily -Trigger $trigDaily -Settings $settDaily -Description 'OpenCode daily health digest at 09:00' -Force

Write-Host "Scheduled tasks registered."
Get-ScheduledTask 'OpenCode*' | Get-ScheduledTaskInfo | Select-Object TaskName, State, LastRunTime, NextRunTime
```

---

## What Gets Checked (every run)

| Check | Failure Mode | Self-Heal |
|-------|-------------|-----------|
| `checkpoint.ps1` exists | Wrong script API → all checkpoints silently fail | Archive the old file |
| `session.yaml` stale >24 h | last_update never refreshed | Touch the last_update field |
| `audit.jsonl` missing | Audit pipeline never ran | Create sentinel file |
| `checkpoint_index.jsonl` entries >20 min apart | Interval checkpoint stopped firing | Log warning |
| `gate-system.log` recent FAILED lines | Checkpoint or memory errors | Log warning |
| No checkpoint files >45 min | Interval checkpoint completely dead | Trigger emergency checkpoint |
| `session_events.jsonl` >30 min old | Event pipeline stalled | Log warning |
| `auto-memory.log` FAILED entries | Memory system errors | Log warning |

---

## Digest Output

When run with `-Digest`, the script outputs clean markdown instead of coloured
console text — suitable for redirecting to a file:

```powershell
powershell -File ~/.config/opencode\scripts\checkpoint-health.ps1 -Digest >> ~/.config/opencode\memory\health-digest.md
```

A daily digest at `memory/health-digest.md` gives you a running history of
system health without needing to open a terminal.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All healthy (or only warnings) |
| `1` | One or more FAILs — needs attention |
| `2` | Self-healed during this run — informational |

The Task Scheduler "If the task fails, restart" setting only triggers on
exit code `1` (application error), not on normal `0` or `2`. Adjust if you
want alerts on self-heal events too.

---

## Dry Run

Before scheduling, preview what the script would do without making changes:

```powershell
powershell -File ~/.config/opencode\scripts\checkpoint-health.ps1 -DryRun
```

This prints every check and whether it would self-heal, without touching any files.