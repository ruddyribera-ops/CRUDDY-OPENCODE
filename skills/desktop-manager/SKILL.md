---
name: desktop-manager
description: Run desktop cleanup scripts using natural language (English or Spanish). Handles Windows 11 desktop organization, temp cleanup, and browser cache management.
tags: [windows, utility, cleanup, os]
---

# Desktop Manager Skill


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

## Purpose
Run desktop cleanup scripts using natural language (English or Spanish). Handles Windows 11 desktop organization, temp file cleanup, and browser cache management.

**Coordinators executes this directly** — no specialist routing needed.

## Triggers (natural language)
- "scan my desktop", "escanear escritorio"
- "organize my desktop", "organizar escritorio"
- "cleanup my desktop", "limpieza de escritorio"
- "quick cleanup", "dry run cleanup"
- "clean temp files", "limpiar archivos temporales"
- "clean downloads", "clean browser cache"

---

## Implementation Architecture


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

Cleanup functions live in Ruddy's PowerShell profile:
- **Profile:** `C:\Users\Windows\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- **Functions:** `dclean`, `dcleanup`, `ds`, `dtemp`, `dbrowser`
- **Backup drive:** `F:\` (external SSD)

---

## Available Commands


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

| Command | Action |
|---|---|
| `ds` | Scan desktop — dry run, shows what would be moved (no changes) |
| `dclean` | Quick cleanup to F:\backup — moves files, no prompts |
| `dcleanup` | Full interactive — preview + confirm before each action |
| `dtemp` | Clean Windows Temp files (`$env:TEMP`) + browser temp |
| `dbrowser` | Clean Chrome + Edge + Firefox cache (quit browsers first) |
| `d` or `desktop` | Navigate to desktop folder |

### Cleanup Targets (Full Table)


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

| Target | Path | Type |
|---|---|---|
| Desktop | `$env:USERPROFILE\Desktop` | Files + Shortcuts |
| Downloads | `$env:USERPROFILE\Downloads` | Files |
| Documents | `$env:USERPROFILE\Documents` | Files |
| Windows Temp | `$env:TEMP` | Files (safe to delete) |
| Chrome Cache | `$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache` | Browser cache |
| Edge Cache | `$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache` | Browser cache |
| Firefox Cache | `$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2` | Browser cache |

---

## Usage Pattern


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

### Coordinator Workflow


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

1. **Detect intent** from user's natural language
2. **Select the right function** based on intent
3. **Execute via PowerShell** using the Bash tool (git bash) or directly
4. **Return summary** of what was moved/freed

### Decision Tree


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

```
User says: "clean my desktop"
  → Is it a scan/dry run? → `ds`
  → Is it quick cleanup? → `dclean`
  → Is it full interactive? → `dcleanup`

User says: "free up space" or "clean temp"
  → `dtemp`

User says: "clean browser cache"
  → `dbrowser` (warn user to close browsers first)
```

### Script Location
The actual cleanup logic is in `~/.config/opencode/skills/desktop-manager/cleanup.ps1`
Coordinator reads this file to understand exact behavior before executing.

---

## Design Notes


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

- Functions create **timestamped backup folders** on F:\ before moving anything
- **No files are deleted** — only moved to backup
- Backup structure: `F:\backup\YYYY-MM-DD_HH-mm\Desktop\...`
- If F:\ not connected, functions fail gracefully (no data loss)
- Browser cleanup requires **all browser windows closed** — function warns

---

## Safety Rules


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

1. **Always do dry run first** (`ds`) when unsure what's on desktop
2. **Warn before browser cleanup** — requires closing Chrome/Edge/Firefox
3. **Never run dcleanup on someone's machine without confirming** — it's interactive and moves files
4. **Backup before cleanup** — the timestamp folder is the safety net

---

## Coordinator Direct-Work Lane


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

This skill is the **only exception** to routing — coordinator executes directly without spawning a specialist. The task is OS utility, not code development.

### Windows Maintenance Ecosystem


## When to Use
- Scan or organize desktop files and folders
- Clean up temporary files and browser cache
- Run desktop cleanup dry-run to preview changes
- Organize downloads folder or documents

## Do Not Use
- System administration or registry editing
- Disk cleanup beyond user-accessible areas
- File recovery or data restoration
- Network or system configuration

- **Tools**: dism, sfc, cleanmgr, diskpart, chkdsk, storesc
- **Temp Locations**: $env:TEMP, $env:WINDIR\Temp, Prefetch, Browser cache
- **Logs**: Event Viewer, Get-WinEvent, wevtutil
- **Performance**: Get-Process, perfmon, resource monitor
- **Disk**: Get-PSDrive, Optimize-Volume (defrag), WMI queries
- **Cleanup Tools**: BleachBit, CCleaner (caution), dism++, PatchCleaner
- **Automation**: Task Scheduler, schtasks, PowerShell scheduled jobs
