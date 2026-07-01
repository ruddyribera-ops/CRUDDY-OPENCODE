# preflight-snapshot.ps1
# Creates timestamped backup snapshots before batch file modifications
# Created after 2026-06-17 PDC destruction incident

param(
    [Parameter(Mandatory=$true)]
    [string[]]$Paths,

    [Parameter(Mandatory=$true)]
    [string]$Operation
)

$ErrorActionPreference = "Continue"
$BASE_DIR = "D:\Temp\opencode"
$FALLBACK_DIR = "C:\Temp"
$LOG_FILE = "$BASE_DIR\BEFORE_LOG.txt"
$AGENT_ROOT = "C:\Users\Windows\.config\opencode"
$BACKUP_ROOT = "D:\Temp\opencode"

function Get-DefaultBackupDir {
    if ((Test-Path $BASE_DIR) -and (Test-Path $BASE_DIR -PathType Container)) {
        try {
            $testFile = "$BASE_DIR\.write_test"
            [System.IO.File]::WriteAllText($testFile, "test")
            Remove-Item $testFile -Force
            return $BASE_DIR
        } catch {}
    }
    if ((Test-Path $FALLBACK_DIR) -and (Test-Path $FALLBACK_DIR -PathType Container)) {
        return $FALLBACK_DIR
    }
    return $null
}

function Get-SnapshotDir {
    param([string]$BackupRoot, [string]$Op)
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    return "$BackupRoot\BEFORE_$timestamp`_$Op"
}

function Test-PathUnderRestricted {
    param([string]$Path)
    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $resolved = $resolved.TrimEnd('\')
    if ($resolved -like "$AGENT_ROOT*") { return $true }
    if ($resolved -like "$BACKUP_ROOT*") { return $true }
    return $false
}

function Copy-WithVerify {
    param([string]$Src, [string]$Dest, [string]$Op)

    if (Test-Path $Src -PathType Container) {
        $destPath = Join-Path $Dest (Split-Path $Src -Leaf)
        Copy-Item -Path $Src -Destination $destPath -Recurse -Force
        if (-not (Test-Path $destPath)) {
            Write-Error "FAILED: $Src -> $destPath (copy failed)"
            return $false
        }
    } else {
        $destDir = Split-Path $Dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $Src -Destination $Dest -Force
        if (-not (Test-Path $Dest)) {
            Write-Error "FAILED: $Src -> $Dest (copy failed)"
            return $false
        }

        $srcSize = (Get-Item $Src).Length
        $destSize = (Get-Item $Dest).Length
        if ($srcSize -gt 0) {
            $pct = [math]::Abs($srcSize - $destSize) / $srcSize * 100
            if ($pct -gt 1) {
                Write-Error "FAILED: $Src -> $Dest (size mismatch: $srcSize vs $destSize)"
                return $false
            }
        }
    }
    return $true
}

$backupDir = Get-DefaultBackupDir
if (-not $backupDir) {
    Write-Error "CRITICAL: Neither $BASE_DIR nor $FALLBACK_DIR is writable"
    exit 1
}

foreach ($p in $Paths) {
    if (Test-PathUnderRestricted $p) {
        Write-Error "REFUSED: Cannot backup agent files or backup location: $p"
        exit 1
    }
    if (-not (Test-Path $p)) {
        Write-Error "REFUSED: Source path does not exist: $p"
        exit 1
    }
}

$snapshotDir = Get-SnapshotDir $backupDir $Operation
New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null

$fileCount = 0
$totalSize = 0
$failures = @()

foreach ($srcPath in $Paths) {
    $resolvedSrc = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($srcPath)
    $itemName = Split-Path $resolvedSrc -Leaf
    $destPath = Join-Path $snapshotDir $itemName

    if (Test-Path $resolvedSrc -PathType Container) {
        $destPath = Join-Path $snapshotDir $itemName
        $srcSize = (Get-ChildItem $resolvedSrc -Recurse -File | Measure-Object -Property Length -Sum).Sum
    } else {
        $srcSize = (Get-Item $resolvedSrc).Length
    }
    $totalSize += $srcSize

    $ok = Copy-WithVerify $resolvedSrc $destPath $Operation
    if ($ok) {
        $fileCount++
    } else {
        $failures += "$srcPath -> $destPath"
    }
}

if ($failures.Count -gt 0) {
    foreach ($f in $failures) {
        Write-Error "VERIFY FAILED: $f"
    }
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = "$timestamp | $Operation | $snapshotDir | $fileCount | $totalSize"
Add-Content -Path $LOG_FILE -Value $logEntry -ErrorAction SilentlyContinue

Write-Output "OK: $fileCount files/dirs backed up to $snapshotDir"
exit 0
