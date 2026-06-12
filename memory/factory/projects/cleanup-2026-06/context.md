# Project cleanup-2026-06

## Brief
# Project Brief: Drive Cleanup and File Organization

**Project ID:** cleanup-2026-06
**Date:** June 9, 2026
**Status:** Approved by user, enqueued to factory pipeline

---

## What the user wants

The user has two drives (C: and D:) that are messy. C: is almost full (145GB used, 6GB free). The user wants the agent team to:

1. **Scan both drives** and catalogue what's there
2. **Identify all projects** (code, design, documents)
3. **Classify trash files** (temp, cache, duplicates, empty folders, old logs, old downloads)
4. **Organize files** into a sensible structure
5. **Clean up trash** (move to a holding folder first, never auto-delete)
6. **Report what was found and what was done**

---

## Constraints and assumptions (AM's calls since user said "I don't know")

### Scope
- **D:\** â€” Scan aggressively. This is the user's main project drive.
- **C:\** â€” Scan conservatively. Only inspect:
  - $env:USERPROFILE\Desktop
  - $env:USERPROFILE\Documents
  - $env:USERPROFILE\Downloads
  - $env:USERPROFILE\AppData\Local\Temp
  - $env:USERPROFILE\AppData\Roaming
  - $env:USERPROFILE\.config
- **NEVER scan or touch**: C:\Windows\, C:\Program Files\, C:\Program Files (x86)\, C:\ProgramData\, C:\System Volume Information\, C:\Recovery\, C:\.Bin\, C:\Boot\, C:\swapfile.sys, C:\hiberfil.sys, C:\pagefile.sys

### What counts as a "project"
A folder is a project if it has any of:
- package.json (Node.js)
- equirements.txt or pyproject.toml (Python)
- composer.json (PHP)
- *.csproj, *.sln (.NET)
- Cargo.toml (Rust)
- pom.xml or uild.gradle (Java)
- go.mod (Go)
- Gemfile (Ruby)
- .git/ directory
- README.md AND a src/ or lib/ folder
- index.html AND a package.json OR webpack.config.js
- Folders under known dev paths: Documents\GitHub, Documents\Projects, D:\Projects, D:\ACTIVE PROJECTS, D:\*projects*

### What counts as "trash"
Safe to classify as trash:
- Files in Temp\ or 	mp\ older than 30 days
- Files matching *.tmp, *.bak, *.swp, *.swo older than 7 days
- 
ode_modules\ folders inside inactive projects (no package.json modified in 6+ months)
- __pycache__\ and *.pyc files
- .vs\ folders, in\, obj\ directories in .NET projects
- dist\, uild\ directories (regeneratable)
- Empty folders
- Duplicate files (same name, same size, different paths) outside of backup folders

NOT trash (must be preserved):
- Files in active projects (modified within 6 months)
- User documents (PDF, DOCX, XLSX, etc.)
- Photos, videos, music
- Anything in C:\Users\Windows\ that looks like a personal file

### Cleanup safety rules
1. **NEVER delete files directly.** Move all trash to $projectDir\trash-holding\ with date-stamped subfolders.
2. **Always show the user what was moved** before they take any action.
3. **Generate a recovery script** at $projectDir\restore-trash.ps1 that can move everything back.
4. **Halt and ask** if total trash exceeds 20GB or affects more than 500 files in a single folder.

### Tools to use
- desktop-commander MCP for fast filesystem ops (read, list, search)
- ash for any cross-platform operations
- sequential-thinking MCP for classification decisions (don't just blast everything as trash)

---

## Success at 90 days

The user can:
1. Open a single DASHBOARD.html file in $projectDir\ and see:
   - Every project on D:\ with size, last-modified, project type
   - Every "mess zone" on C:\ (Desktop, Downloads) with trash counts
   - A recommended action plan
2. Run a single command to apply the cleanup
3. Run a single command to undo the cleanup (restore from holding folder)
4. Have at least 10GB free on C:\

---

## Out of scope (NOT building this)

- Anything cloud-based (no OneDrive, Google Drive, Dropbox sync)
- Anything that touches C:\Windows\ or Program Files
- Auto-deletion of any file (always move to holding folder first)
- Any user account changes, system config changes, or driver updates
- Defragmentation, disk cleanup utilities, registry edits
- Any tool that requires admin privileges

---

## Decisions still pending

These are flagged for PM/Architect to decide:
- Whether to install a system tray app or keep it as a one-shot tool
- Whether to schedule recurring scans or just do it once
- Whether to integrate with the existing desktop-manager skill

---

## Handoff chain

1. **AM (done)** â€” this brief
2. **PM (next)** â€” sprint plan
3. **Architect** â€” design approach
4. **Tech Lead** â€” break into tasks
5. **Builder** â€” write the code
6. **QA** â€” test
7. **Delivery** â€” show user the dashboard

---

## Notes for the team

- The user is non-technical. Plain language in any user-facing output.
- The user said "I don't know" to scoping questions. AM made conservative assumptions. PM/Architect should validate these before scanning.
- The user wants this done â€” they have C: almost full and can't find anything.
- The dispatcher service is already running. This brief just enqueued. PM will pick it up within 3 seconds.
