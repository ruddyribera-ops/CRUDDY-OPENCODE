# System Optimization POA
**Date:** 2026-05-17
**Goal:** Free disk space on C:, reduce memory usage, optimize laptop performance

---

## Priority 1 — CRITICAL: C: Drive Full (5.6 GB free)

### 1.1 Clean Temp Files (~2.4 GB immediate)
```
Target: $env:TEMP + $env:WINDIR\Temp
Risk: None (temp files, safe to delete)
Command: Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Backup: No (temp files, no backup needed)
```

### 1.2 Empty Recycle Bin (~1-5 GB)
```
Target: Recycle Bin C:\
Risk: None (user explicitly asked to clean)
Command: Clear-RecycleBin -Force
```

### 1.3 Windows Update Cleanup (~2-5 GB)
```
Target: $env:WINDIR\SoftwareDistribution\Download
Risk: Low (Windows re-downloads if needed)
Command: dism /online /cleanup-image /startcomponentcleanup /resetbase
```

### 1.4 Windows Store Cache (Packages: 16.2 GB → target 8 GB)
```
Target: $env:LOCALAPPDATA\Packages\*\LocalCache
Risk: Medium (may affect Windows Store apps)
Action: Identify large packages first, remove cache only
Command: Get-AppxPackage | Sort-Object -Property PackageCacheSize -Descending | Select-Object Name, PackageCacheSize
```
⚠️ Do NOT delete AppxPackage itself — only cache under LocalCache

### 1.5 NVIDIA Cache (~0.5-5 GB)
```
Target: $env:LOCALAPPDATA\NVIDIA\*
Risk: Low (re-downloads on demand)
Command: Remove-Item "$env:LOCALAPPDATA\NVIDIA\*" -Recurse -Force -ErrorAction SilentlyContinue
Exception: Keep ShaderCache (rebuild slows gaming)
```

---

## Priority 2 — HIGH: Memory Optimization

### 2.1 WSL Memory/RAM (2.6 GB used)
```
Status: vmmemWSL consuming 2.6 GB RAM
Issue: WSL running even when not actively used
Actions:
  - If Docker not needed: docker desktop stop + wsl --shutdown
  - If WSL needed: set memory limit in .wslconfig
Command (shutdown): wsl --shutdown
Command (config): New-Item -Path "$env:USERPROFILE\.wslconfig" -Value "[wsl2]`nmemory=4GB`nprocessors=4"
```

### 2.2 Docker Desktop (195 MB RAM)
```
Status: com.docker.backend running
Issue: Docker consuming resources even idle
Actions:
  - If project uses Docker: reduce memory limit
  - If not: docker desktop quit
Config: Docker Desktop → Settings → Resources → memory 4GB (from 8GB)
```

### 2.3 OpenCode Session Memory (1.7 GB combined)
```
Status: 2 opencode processes using ~1.7 GB
Issue: This session + another session running
Action: If not needed, close duplicate session
Command: Get-Process -Name "opencode" | Select-Object Id, WorkingSet64 | Format-Table
```

---

## Priority 3 — MEDIUM: Disk Space on C:

### 3.1 Browser Caches (small but easy)
```
Chrome: ~0.01 GB (already small)
Edge: ~0.01 GB (already small)
Firefox: ~0.09 GB (already small)
Action: Optional, very low priority
```

### 3.2 Google Folder (7.9 GB)
```
Breakdown: Google Chrome + Google Drive + Google Update
Action: Check what's inside
  - Chrome cache: small (already checked)
  - Google Drive: local sync files
  - Backup: move if local-only
Command: Get-ChildItem "$env:LOCALAPPDATA\Google" -Depth 1 | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "$($_.Name): $([math]::Round($size,1)) GB"
}
```

### 3.3 Windows Cleanup Tool (Automated)
```
Command: cleanmgr /d C:
Actions:
  - Windows Update cleanup
  - Recycle Bin
  - Temporary files
  - Thumbnail cache
  - Previous Windows installations (may free 10-20 GB)
Warning: Takes 30-60 minutes
```

### 3.4 Previous Windows Installations
```
Target: $env:WINDIR\Windows.old
Size: Typically 10-20 GB after major updates
Risk: None if you don't need rollback
Command: takeown /F C:\Windows.old /A /R /DY && icacls C:\Windows.old /grant administrators:F /T && rd /s /q C:\Windows.old
Space if freed: 10-20 GB
```

---

## Priority 4 — LOW: Long-term Maintenance

### 4.1 Defragment/Optimize C: Drive
```
Command: Optimize-Volume -DriveLetter C -Defrag
Time: 1-3 hours depending on fragmentation
Note: Only for HDD, SSD should not defrag (use TRIM instead)
```

### 4.2 Windows Services Optimization
```
Actions: Disable unnecessary startup services
Command: Get-CimInstance Win32_Service | Where-Object {$_.StartMode -eq 'Auto' -and $_.State -eq 'Running'} | Select-Object Name, DisplayName | Sort-Object DisplayName
Risk: Medium (don't disable Windows security services)
```

### 4.3 Scheduled Tasks Cleanup
```
Target: Unused scheduled tasks consuming disk/CPU
Command: Get-ScheduledTask | Where-Object {$_.State -eq 'Ready'} | Select-Object TaskName, Author
```

---

## Execution Order

```
Step 1:  (IMMEDIATE) Clean temp files → ~2.4 GB freed
Step 2:  (IMMEDIATE) Empty Recycle Bin → ~1-5 GB freed  
Step 3:  (IMMEDIATE) Windows Update cache cleanup → ~2-5 GB freed
Step 4:  (URGENT)    Windows.old removal → ~10-20 GB freed
Step 5:  (URGENT)    Identify large packages → target 8 GB from 16 GB
Step 6:  (HIGH)      WSL memory limit config → save 2.6 GB RAM
Step 7:  (HIGH)      Docker memory reduction → save ~1 GB RAM
Step 8:  (MEDIUM)     Google folder analysis → identify big folders
Step 9:  (MEDIUM)     NVIDIA cache cleanup → ~0.5-5 GB freed
Step 10: (LOW)        Schedule Disk Cleanup monthly
```

---

## Verification Checklist

After each step, verify:
- [ ] C: free space increased
- [ ] Memory usage decreased
- [ ] No broken functionality

| Step | Expected Free Space | Verify Command |
|------|-------------------|----------------|
| 1-3  | +5-10 GB | Get-PSDrive C | 
| 4    | +10-20 GB | Get-PSDrive C |
| 5    | +8 GB | Get-PSDrive C |
| 6-7  | -3.6 GB RAM | Task Manager |
| 8-9  | +1-5 GB | Get-PSDrive C |

---

## Rollback Plan

- Temp files: No rollback needed (regenerated)
- Recycle Bin: No rollback (user intent)
- Windows.old: No rollback if not needed (can recreate via Windows reinstall)
- WSL config: Edit .wslconfig to restore defaults
- Docker: Reset via Docker Desktop settings
- NVIDIA: Will rebuild ShaderCache on next use

---

## Files to Monitor

```
$env:LOCALAPPDATA\Packages\    (target: reduce from 16 GB to 8 GB)
$env:LOCALAPPDATA\Google\      (analyze, don't auto-delete)
$env:LOCALAPPDATA\NVIDIA\      (clean cache only)
$env:TEMP\                     (keep clean, monthly)
$env:WINDIR\Windows.old        (delete after verify no rollback needed)
Recycle Bin                    (empty monthly)
```

---

## Success Metrics

| Metric | Before | Target | After |
|--------|--------|--------|-------|
| C: free space | 5.6 GB | 30+ GB | _GB |
| RAM usage | 12.2/15.3 GB (80%) | <70% | _GB |
| WSL RAM | 2.6 GB | 0-4 GB | _GB |
| Temp size | 2.36 GB | <0.5 GB | _GB |