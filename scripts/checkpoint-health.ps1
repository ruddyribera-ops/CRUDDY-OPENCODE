# checkpoint-health.ps1
# Periodic auto-analysis for OpenCode checkpoint + session survival system.
# Run: powershell -File checkpoint-health.ps1 [-DryRun] [-Digest] [-SessionStaleHours 24]
param(
    [int]$SessionStaleHours = 24,
    [int]$CheckpointStaleMinutes = 45,
    [int]$CheckpointIntervalMaxMinutes = 20,
    [switch]$Verbose,
    [switch]$DryRun,
    [switch]$digestOutput
)

$ErrorActionPreference = "Continue"
$configDir = $env:OPENCODE_CONFIG_HOME
if (-not $configDir) { $configDir = Join-Path $env:USERPROFILE ".config\opencode" }

$scriptsDir    = Join-Path $configDir "scripts"
$memoryDir     = Join-Path $configDir "memory"
$gatesDir      = Join-Path $configDir "gates"
$checkpointsDir = Join-Path $memoryDir "checkpoints"
$pluginsDir    = Join-Path $configDir "plugins"
$now           = Get-Date
$reportTime    = $now.ToString("yyyy-MM-dd HH:mm:ss")
$script:healed   = $false
$script:failCount = 0
$script:warnCount = 0
$script:digestSections = @()

function Log {
    param([string]$Msg, [string]$Level = "INFO")
    if ($digestOutput) { return }
    $color = switch ($Level) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "HEAL" { "Cyan" }
        default { "White" }
    }
    $prefix = switch ($Level) {
        "PASS" { "  [PASS]" }
        "FAIL" { "  [FAIL]" }
        "WARN" { "  [WARN]" }
        "HEAL" { "  [HEAL]" }
        default { "  [INFO]" }
    }
    Write-Host "$prefix $Msg" -ForegroundColor $color
}

function Log-Digest {
    param([string]$Section, [string]$Body)
    if (-not $digestOutput) { return }
    $script:digestSections += [PSCustomObject]@{ Section = $Section; Body = $Body }
}

Log "=== OpenCode Health Check ===" "INFO"
Log "Time: $reportTime" "INFO"

# ── 1. checkpoint.ps1 should NOT exist ────────────────────────────────────────
Log "=== Checkpoint Script Integrity ===" "INFO"

$wrongCheckpoint = Join-Path $scriptsDir "checkpoint.ps1"
$rightCheckpoint = Join-Path $scriptsDir "checkpoint-save.ps1"

if (Test-Path $wrongCheckpoint) {
    $size = (Get-Item $wrongCheckpoint).Length
    Log "checkpoint.ps1 EXISTS ($size bytes) - causes silent failures" "FAIL"
    Log "  checkpoint-guard.js calls checkpoint.ps1 but it has a different API" "FAIL"
    Log "  than checkpoint-save.ps1.  All checkpoint attempts silently fail." "FAIL"
    if (-not $DryRun) {
        $archiveDir = Join-Path $scriptsDir "bash-guardian"
        if (-not (Test-Path $archiveDir)) { $archiveDir = $scriptsDir }
        $archivedPath = Join-Path $archiveDir ("checkpoint-OLD-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".ps1")
        Move-Item -LiteralPath $wrongCheckpoint -Destination $archivedPath -Force
        Log "  Archived to: $archivedPath" "HEAL"
        $script:healed = $true
    } else {
        Log "  [DryRun] Would archive checkpoint.ps1" "HEAL"
    }
    $script:failCount++
} else {
    Log "checkpoint.ps1 absent (good)" "PASS"
}

if (-not (Test-Path $rightCheckpoint)) {
    Log "checkpoint-save.ps1 is MISSING - interval checkpoints cannot fire" "FAIL"
    $script:failCount++
} else {
    Log "checkpoint-save.ps1 present ($((Get-Item $rightCheckpoint).Length) bytes)" "PASS"
}

# ── 2. session.yaml last_update within 24 h ───────────────────────────────────
Log "=== Session State Freshness ===" "INFO"

$sessionYaml = Join-Path $memoryDir "session.yaml"
if (Test-Path $sessionYaml) {
    $lastWrite = (Get-Item $sessionYaml).LastWriteTime
    $ageHours  = ($now - $lastWrite).TotalHours
    $yamlContent = Get-Content $sessionYaml -Raw

    if ($yamlContent -match "last_update:\s*\x22([^\x22]+)\x22") {
        try { $ageHours = ($now - [DateTime]::Parse($matches[1])).TotalHours } catch {}
    }

    if ($ageHours -gt $SessionStaleHours) {
        Log "session.yaml is STALE (last update $([Math]::Round($ageHours,1)) h ago)" "FAIL"
        Log "  Last write: $($lastWrite.ToString("yyyy-MM-dd HH:mm"))" "FAIL"
        if (-not $DryRun) {
            if ($yamlContent -match "(last_update:\s*\x22)[^\x22]+(\x22)") {
                $yamlContent = $yamlContent -replace $matches[0], ($matches[1] + $now.ToString("yyyy-MM-ddTHH:mm:ss") + $matches[2])
            } elseif ($yamlContent -match "(session_id:\s*\x22[^\x22]+\x22)") {
                $yamlContent = $yamlContent -replace [regex]::Escape($matches[1]), ($matches[1] + "`nlast_update: `"" + $now.ToString("yyyy-MM-ddTHH:mm:ss") + "`"")
            }
            $yamlContent | Out-File -FilePath $sessionYaml -Encoding UTF8 -NoNewline
            Log "  Refreshed last_update to $($now.ToString("yyyy-MM-dd HH:mm:ss"))" "HEAL"
            $script:healed = $true
        } else {
            Log "  [DryRun] Would refresh last_update in session.yaml" "HEAL"
        }
        $script:failCount++
    } else {
        Log "session.yaml fresh ($([Math]::Round($ageHours,1)) h old)" "PASS"
    }
} else {
    Log "session.yaml is MISSING - session tracking offline" "FAIL"
    if (-not $DryRun) {
        $skeleton = @(
            "# Session state - auto-generated by checkpoint-health.ps1",
            "session_name: `"Unknown`"",
            ("session_id: `"unknown-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "`""),
            ("last_update: `"" + $now.ToString("yyyy-MM-ddTHH:mm:ss") + "`"")
        ) -join "`n"
        $skeleton | Out-File -FilePath $sessionYaml -Encoding UTF8
        Log "  Created skeleton session.yaml" "HEAL"
        $script:healed = $true
    }
    $script:failCount++
}

# ── 3. audit.jsonl exists and growing ─────────────────────────────────────────
Log "=== Audit Pipeline ===" "INFO"

$auditJsonl = Join-Path $memoryDir "audit.jsonl"
if (-not (Test-Path $auditJsonl)) {
    Log "audit.jsonl is MISSING - audit pipeline has never run" "FAIL"
    if (-not $DryRun) {
        @{ type = "health_check"; timestamp = $now.ToString("o"); event = "sentinel_created"; note = "audit.jsonl did not exist - created by checkpoint-health.ps1" } | ConvertTo-Json -Compress | Out-File $auditJsonl -Encoding UTF8
        Log "  Created sentinel audit.jsonl" "HEAL"
        $script:healed = $true
    }
    $script:failCount++
} else {
    $lastEntry = Get-Content $auditJsonl -Tail 1 -ErrorAction SilentlyContinue
    if ($lastEntry -match '"\s*timestamp"\s*:\s*"\x22?([^\x22]+)\x22?') {
        try {
            $lastTs = [DateTime]::Parse($matches[1])
            $ageH = ($now - $lastTs).TotalHours
            if ($ageH -gt 24) {
                Log "audit.jsonl last entry is $([Math]::Round($ageH,1)) h old - pipeline stalled" "WARN"
                $script:warnCount++
            } else {
                Log "audit.jsonl healthy (last entry $([Math]::Round($ageH,1)) h ago)" "PASS"
            }
        } catch {
            Log "audit.jsonl last entry unparseable" "WARN"
            $script:warnCount++
        }
    } else {
        Log "audit.jsonl exists but has no recognisable entries" "WARN"
        $script:warnCount++
    }
}

# ── 4. checkpoint_index.jsonl recent entries ───────────────────────────────────
Log "=== Checkpoint Interval Health ===" "INFO"

$checkpointIndex = Join-Path $checkpointsDir "checkpoint_index.jsonl"
if (Test-Path $checkpointIndex) {
    $lines = Get-Content $checkpointIndex
    $lineCount = $lines.Count
    $lastLine  = $lines[-1]
    if ($lastLine -match '"\s*timestamp"\s*:\s*"\x22?([^\x22]+)\x22?') {
        try {
            $lastTs  = [DateTime]::Parse($matches[1])
            $ageMins = ($now - $lastTs).TotalMinutes
            Log "checkpoint_index.jsonl: $lineCount entries, last $([Math]::Round($ageMins,0)) min ago" "PASS"
            if ($ageMins -gt $CheckpointIntervalMaxMinutes) {
                Log "  Last checkpoint > ${CheckpointIntervalMaxMinutes} min ago - interval may be stuck" "WARN"
                $script:warnCount++
            }
        } catch {
            Log "  Last index entry has unparseable timestamp" "WARN"
            $script:warnCount++
        }
    } else {
        Log "  Last index entry unparseable (corrupt?)" "WARN"
        $script:warnCount++
    }
} else {
    Log "checkpoint_index.jsonl MISSING - no checkpoints ever recorded" "FAIL"
    $script:failCount++
}

# ── 5. gate-system.log recent failures ────────────────────────────────────────
Log "=== Gate System Log ===" "INFO"

$gateLog = Join-Path $memoryDir "gate-system.log"
if (Test-Path $gateLog) {
    $allLines = Get-Content $gateLog
    $totalLines = $allLines.Count
    $windowStart = [Math]::Max(0, $totalLines - 500)
    $recentSlice = $allLines | Select-Object -Skip $windowStart
    $failLines = $recentSlice | Select-String -Pattern "FAILED","CHECKPOINT_FAIL","ERROR" -SimpleMatch
    if ($failLines) {
        Log "gate-system.log has $($failLines.Count) recent failure lines" "WARN"
        foreach ($f in ($failLines | Select-Object -First 3)) {
            $snippet = $f.Line.Substring(0, [Math]::Min(100, $f.Line.Length))
            Log "  Line $($f.LineNumber): $snippet" "WARN"
        }
        $script:warnCount++
    } else {
        Log "gate-system.log: no recent failures" "PASS"
    }
} else {
    Log "gate-system.log does not exist" "WARN"
    $script:warnCount++
}

# ── 6. checkpoint files being created ─────────────────────────────────────────
if (Test-Path $checkpointsDir) {
    $cpFiles = Get-ChildItem $checkpointsDir -Filter "*.json" -File | Sort-Object LastWriteTime -Descending
    if ($cpFiles.Count -gt 0) {
        $newest = $cpFiles[0]
        $ageMins = ($now - $newest.LastWriteTime).TotalMinutes
        if ($ageMins -gt $CheckpointStaleMinutes) {
            Log "Newest checkpoint file is $([Math]::Round($ageMins,0)) min old - interval checkpoint may be down" "WARN"
            $script:warnCount++
        } else {
            Log "Checkpoint files: $($cpFiles.Count) files, newest $([Math]::Round($ageMins,0)) min old" "PASS"
        }
    } else {
        Log "No checkpoint JSON files in memory/checkpoints/" "WARN"
        $script:warnCount++
    }
} else {
    Log "memory/checkpoints/ directory does not exist" "FAIL"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $checkpointsDir -Force | Out-Null
        Log "  Created memory/checkpoints/ directory" "HEAL"
        $script:healed = $true
    }
    $script:failCount++
}

# ── 7. session_events.jsonl growth check ───────────────────────────────────────
Log "=== Session Events Pipeline ===" "INFO"

$eventsFile = Join-Path $memoryDir "session_events.jsonl"
if (Test-Path $eventsFile) {
    $size = (Get-Item $eventsFile).Length
    $lines = (Get-Content $eventsFile).Count
    $lastLine = Get-Content $eventsFile -Tail 1 -ErrorAction SilentlyContinue
    $isGrowing = $false
    if ($lastLine -and $lastLine -match '"\s*timestamp"\s*:\s*"\x22?([^\x22]+)\x22?') {
        try {
            $lastTs = [DateTime]::Parse($matches[1])
            $isGrowing = ($now - $lastTs).TotalMinutes -lt 30
        } catch {}
    }
    if ($isGrowing) {
        Log "session_events.jsonl: $lines entries, $([Math]::Round($size/1KB,1)) KB, recent activity" "PASS"
    } else {
        Log "session_events.jsonl: $lines entries, $([Math]::Round($size/1KB,1)) KB, no recent activity (>30 min)" "WARN"
        $script:warnCount++
    }
} else {
    Log "session_events.jsonl MISSING - event pipeline not running" "FAIL"
    $script:failCount++
}

# ── 8. auto-memory.log failure check ──────────────────────────────────────────
Log "=== Auto-Memory Log ===" "INFO"

$autoMemLog = Join-Path $memoryDir "auto-memory.log"
if (Test-Path $autoMemLog) {
    $failLines = Select-String -Path $autoMemLog -Pattern "status=FAILED" -SimpleMatch | Select-Object -Last 5
    if ($failLines) {
        Log "auto-memory.log has $($failLines.Count) recent FAILED entries" "WARN"
        $script:warnCount++
    } else {
        $lastLine = Get-Content $autoMemLog -Tail 1
        if ($lastLine -match "status=(\w+)") {
            Log "auto-memory.log: last entry status = $($matches[1])" "PASS"
        } else {
            Log "auto-memory.log exists but has no parseable entries" "WARN"
            $script:warnCount++
        }
    }
} else {
    Log "auto-memory.log MISSING - auto-memory never ran" "FAIL"
    $script:failCount++
}

# ── Self-heal: Emergency checkpoint if too old ─────────────────────────────────
if (-not $DryRun -and (Test-Path $checkpointIndex)) {
    $lines = Get-Content $checkpointIndex
    $lastLine = $lines[-1]
    if ($lastLine -match '"\s*timestamp"\s*:\s*"\x22?([^\x22]+)\x22?') {
        try {
            $lastTs = [DateTime]::Parse($matches[1])
            $ageMins = ($now - $lastTs).TotalMinutes
            if ($ageMins -gt $CheckpointStaleMinutes) {
                Log "Last checkpoint was $([Math]::Round($ageMins,0)) min ago - triggering emergency checkpoint" "HEAL"
                $sessionId = "health-check-recovery"
                $yamlContent = Get-Content $sessionYaml -Raw -ErrorAction SilentlyContinue
                if ($yamlContent -and $yamlContent -match "session_id:\s*\x22([^\x22]+)\x22") { $sessionId = $matches[1] }
                $epResult = & $rightCheckpoint -SessionId $sessionId -ProgressPercent 0 -Strategy "emergency-recovery" -NextAction "resuming after health-check recovery" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Log "  Emergency checkpoint saved successfully" "HEAL"
                    $script:healed = $true
                } else {
                    Log "  Emergency checkpoint failed: $($epResult | Out-String)" "FAIL"
                    $script:failCount++
                }
            }
        } catch {
            Log "  Could not determine checkpoint age for emergency heal: $_" "WARN"
        }
    }
}

# ── Summary ────────────────────────────────────────────────────────────────────
Log "=== Health Summary ===" "INFO"

if ($digestOutput) {
    $digestOutput = "# OpenCode Health Digest - $reportTime`n`n"
    foreach ($s in $script:digestSections) {
        $digestOutput += "## $($s.Section)`n$($s.Body)`n`n"
    }
    if ($script:failCount -gt 0) { $digestOutput += "**Result:** FAIL ($($script:failCount) failures)`n" }
    elseif ($script:warnCount -gt 0) { $digestOutput += "**Result:** WARN ($($script:warnCount) warnings)`n" }
    elseif ($script:healed) { $digestOutput += "**Result:** HEALED (self-repaired)`n" }
    else { $digestOutput += "**Result:** PASS (all systems nominal)`n" }
    Write-Output $digestOutput
}

$color = if ($script:failCount -gt 0) { "Red" } elseif ($script:warnCount -gt 0) { "Yellow" } else { "Green" }
Write-Host ""
Write-Host "  FAIL: $($script:failCount)   WARN: $($script:warnCount)   HEAL: $script:healed" -ForegroundColor $color
Write-Host ""

if ($script:healed -and $script:failCount -eq 0 -and $script:warnCount -eq 0) {
    Write-Host "  Self-healed - no failures remaining." -ForegroundColor Cyan
    exit 2
} elseif ($script:failCount -gt 0) {
    Write-Host "  Fix the FAIL items above - run with -DryRun to preview changes." -ForegroundColor Red
    exit 1
} elseif ($script:warnCount -gt 0) {
    Write-Host "  Warnings present - monitor but no immediate action required." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "  All systems nominal." -ForegroundColor Green
    exit 0
}