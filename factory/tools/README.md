# Preflight Snapshot Tools

## Overview
Creates timestamped backup snapshots of files and directories before batch modifications. Verifies copies using SHA256 (Python) or size tolerance (PowerShell) to ensure backup integrity.

## Historical Context
Created after the **2026-06-17 PDC destruction incident** — a batch file operation corrupted user data with no recovery path. These tools provide a safety net: snapshot before, verify, restore if needed.

## When to Use
**BEFORE any batch file modification on user data.** Specifically:
- Batch rename/delete/modify operations
- Multi-file refactoring
- Directory restructuring
- Any operation where mistakes are costly and irreversible

## Usage

### PowerShell
```powershell
# Single file
.\preflight-snapshot.ps1 -Paths "C:\data\file.txt" -Operation "cleanup"

# Multiple paths
.\preflight-snapshot.ps1 -Paths "C:\data\file1.txt","C:\data\folder" -Operation "refactor"
```

### Python
```powershell
# Single file
python preflight-snapshot.py --paths "C:\data\file.txt" --operation "cleanup"

# Multiple paths (comma-separated)
python preflight-snapshot.py --paths "C:\data\file1.txt,C:\data\folder" --operation "refactor"
```

## Exit Codes
| Code | Meaning |
|------|---------|
| 0 | Success — all files verified |
| 1 | Failure — copy/verify failed or refused |

## Output
- **Snapshot dir:** `D:\Temp\opencode\BEFORE_{timestamp}_{operation}\`
- **Log file:** `D:\Temp\opencode\BEFORE_LOG.txt` (appends each run)

## Refusal Rules
Tool **refuses** to backup if source is under:
- `~/.config/opencode/` (agent's own files)
- `D:\Temp\opencode\` (backup location itself)

## Restore Procedure
To restore from a snapshot:
```powershell
# PowerShell
Copy-Item -Path "D:\Temp\opencode\BEFORE_20260618-143052_cleanup\*" -Destination "C:\target\" -Recurse -Force

# Python
import shutil
shutil.copytree("D:/Temp/opencode/BEFORE_20260618-143052_cleanup/", "C:/target/", dirs_exist_ok=True)
```
