# install-pre-push-gate.ps1
# Installer for the pre-push test gate hook.
# Copies the hook into a target git repo and creates a Windows-compatible
# wrapper so git can invoke the PowerShell script reliably.
#
# === USAGE ===
#
#   pwsh -NoProfile -File "$env:USERPROFILE\.config\opencode\scripts\install-pre-push-gate.ps1"
#     # installs into the current directory (must be inside a git repo)
#
#   pwsh -NoProfile -File "$env:USERPROFILE\.config\opencode\scripts\install-pre-push-gate.ps1" -ProjectPath "C:\code\my-app"
#     # installs into a specific repo
#
#   pwsh -NoProfile -File "$env:USERPROFILE\.config\opencode\scripts\install-pre-push-gate.ps1" -Global
#     # installs into a shared hooks dir and points core.hooksPath at it
#     # (applies to every repo on this machine)
#
#   pwsh -NoProfile -File "$env:USERPROFILE\.config\opencode\scripts\install-pre-push-gate.ps1" -Uninstall -ProjectPath "C:\code\my-app"
#     # removes the hook from a repo
#
# === WHAT IT DOES ===
#
#   1. Validates the target is a git repo (has .git/).
#   2. Creates .git/hooks/ if missing.
#   3. Copies pre-push-test-gate.ps1 into .git/hooks/pre-push-test-gate.ps1.
#   4. Creates .git/hooks/pre-push (no extension) with a shebang + the
#      script body, so modern git for Windows can find pwsh on PATH.
#   5. Creates .git/hooks/pre-push.cmd as a fallback wrapper for older
#      git for Windows builds that ignore shebangs.
#   6. Backs up any existing pre-push hook to pre-push.backup-<timestamp>.

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectPath = "",
    [switch]$Global,
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- Paths --------------------------------------------------------------------
$scriptSource = Join-Path $env:USERPROFILE ".config\opencode\scripts\pre-push-test-gate.ps1"
$sharedHooksDir = Join-Path $env:USERPROFILE ".config\opencode\git-hooks"

function Write-Step($msg)  { Write-Host "[install] " -NoNewline -ForegroundColor Cyan; Write-Host $msg }
function Write-Ok($msg)    { Write-Host "[install] " -NoNewline -ForegroundColor Green; Write-Host $msg }
function Write-Warn($msg)  { Write-Host "[install] " -NoNewline -ForegroundColor Yellow; Write-Host $msg }
function Write-Err($msg)   { Write-Host "[install] " -NoNewline -ForegroundColor Red; Write-Host $msg; exit 1 }

# --- Sanity: source file must exist -------------------------------------------
if (-not (Test-Path -LiteralPath $scriptSource)) {
    Write-Err "Source hook not found at: $scriptSource"
}

# --- Resolve target project + hooks dir ---------------------------------------
if ($Global) {
    $projectRoot = $sharedHooksDir
    $hooksDir    = $sharedHooksDir
    if (-not (Test-Path -LiteralPath $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }
    Write-Step "Global mode: installing into $hooksDir"
    Write-Step "Will set core.hooksPath = $hooksDir (applies to all repos for this user)"
} else {
    if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
        $ProjectPath = (Get-Location).Path
    }
    $projectRoot = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
    $gitDir      = Join-Path $projectRoot ".git"
    if (-not (Test-Path -LiteralPath $gitDir)) {
        Write-Err "Not a git repository: $projectRoot (no .git/ found)"
    }
    $hooksDir = Join-Path $gitDir "hooks"
    if (-not (Test-Path -LiteralPath $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }
    Write-Step "Target repo: $projectRoot"
    Write-Step "Hooks dir:   $hooksDir"
}

$destPs1  = Join-Path $hooksDir "pre-push-test-gate.ps1"
$destHook = Join-Path $hooksDir "pre-push"
$destCmd  = Join-Path $hooksDir "pre-push.cmd"

# --- Uninstall path -----------------------------------------------------------
if ($Uninstall) {
    Write-Step "Uninstall mode: removing hook files from $hooksDir"
    foreach ($f in @($destPs1, $destHook, $destCmd)) {
        if (Test-Path -LiteralPath $f) {
            Remove-Item -LiteralPath $f -Force
            Write-Ok "removed: $f"
        }
    }
    if ($Global) {
        git config --global --unset core.hooksPath 2>$null
        Write-Ok "unset global core.hooksPath"
    }
    Write-Ok "Uninstall complete."
    exit 0
}

# --- Backup any existing pre-push hook ---------------------------------------
if ((Test-Path -LiteralPath $destHook) -or (Test-Path -LiteralPath $destCmd)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    if ($Force) {
        Write-Warn "-Force set: overwriting existing hook without backup"
    } else {
        foreach ($f in @($destHook, $destCmd)) {
            if (Test-Path -LiteralPath $f) {
                $ext = [System.IO.Path]::GetExtension($f)
                $base = [System.IO.Path]::GetFileNameWithoutExtension($f)
                $backup = Join-Path $hooksDir ("$base.backup-$stamp$ext")
                Move-Item -LiteralPath $f -Destination $backup -Force
                Write-Warn "Backed up existing $f -> $backup"
            }
        }
    }
}

# --- Copy the PowerShell script ----------------------------------------------
Copy-Item -LiteralPath $scriptSource -Destination $destPs1 -Force
Write-Ok "copied hook script -> $destPs1"

# --- Create the shebang version (cross-platform) -----------------------------
# Read the script content, prepend a shebang line. The shebang is a comment
# in PowerShell so it doesn't break the script, and modern git for Windows
# honors it to find pwsh on PATH.
$scriptBody = Get-Content -LiteralPath $scriptSource -Raw
$shebangHook = "#!/usr/bin/env pwsh`r`n" + $scriptBody
Set-Content -LiteralPath $destHook -Value $shebangHook -NoNewline -Encoding UTF8
Write-Ok "created shebang wrapper -> $destHook"

# --- Create the .cmd wrapper (Windows fallback) ------------------------------
# Some older git for Windows builds ignore shebangs. The .cmd wrapper
# explicitly invokes pwsh and forwards stdin (git sends ref data via stdin).
$cmdBody = @"
@echo off
rem Auto-generated by opencode pre-push-gate installer ($([DateTime]::Now.ToString('s'))).
rem Forwards this hook invocation to the PowerShell script in the same dir.
rem Stdin (ref data from git) is inherited automatically.

setlocal
set "HOOK_DIR=%~dp0"
set "HOOK_PS1=%HOOK_DIR%pre-push-test-gate.ps1"

if not exist "%HOOK_PS1%" (
    echo [install] ERROR: hook script missing: %HOOK_PS1% 1>&2
    exit /b 1
)

where pwsh >nul 2>&1
if %ERRORLEVEL%==0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%HOOK_PS1%" %*
    exit /b %ERRORLEVEL%
)

where powershell >nul 2>&1
if %ERRORLEVEL%==0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HOOK_PS1%" %*
    exit /b %ERRORLEVEL%
)

echo [install] ERROR: no PowerShell executable (pwsh or powershell) found on PATH 1>&2
exit /b 1
"@
Set-Content -LiteralPath $destCmd -Value $cmdBody -Encoding ASCII
Write-Ok "created Windows batch wrapper -> $destCmd"

# --- If global, set core.hooksPath -------------------------------------------
if ($Global) {
    git config --global core.hooksPath $hooksDir
    Write-Ok "set global core.hooksPath = $hooksDir"
}

# --- Final report -------------------------------------------------------------
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Pre-push test gate installed successfully." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed files:" -ForegroundColor Cyan
Write-Host "  - $destPs1"
Write-Host "  - $destHook"
Write-Host "  - $destCmd"
Write-Host ""
Write-Host "How it works:" -ForegroundColor Cyan
Write-Host "  - Pushes to main/master: runs detected tests, blocks on failure."
Write-Host "  - Pushes to other branches: skipped (fast dev workflow)."
Write-Host "  - No test framework detected: warns but allows push."
Write-Host ""
Write-Host "Verify install:" -ForegroundColor Cyan
Write-Host "  cd <project-with-the-hook> ; git push origin main --dry-run  # or just try a real push"
Write-Host ""
Write-Host "Uninstall:" -ForegroundColor Cyan
if ($Global) {
    $uninstallExample = "pwsh -NoProfile -File `"$PSCommandPath`" -Uninstall -Global"
} else {
    $uninstallExample = "pwsh -NoProfile -File `"$PSCommandPath`" -Uninstall -ProjectPath `"$projectRoot`""
}
Write-Host "  $uninstallExample"
Write-Host ""
Write-Host "Log file: $env:USERPROFILE\.config\opencode\memory\gate-system.log" -ForegroundColor DarkGray
exit 0
