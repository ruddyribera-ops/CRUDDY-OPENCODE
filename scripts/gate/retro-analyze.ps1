# retro-analyze.ps1
# Reads gate history → outputs JSON insights + optionally auto-writes gene candidates to DNA.yaml
# Exit codes: 0=analysis only, 1=error, 2=genes written (trigger evolution-agent)
param(
    [int]$TaskCount = 10,
    [string]$OutputFile = "",
    [switch]$WriteGenes,    # When set: auto-write gene candidates to DNA.yaml
    [switch]$DryRun         # Preview genes without writing
)
$ErrorActionPreference = "Continue"
$gateRoot = "$env:CONFIG\gates"
$dnaPath = "$env:CONFIG\skills\DNA.yaml"
$genesWritten = 0

# ── Step 1: Analyze gate history ───────────────────────────────
$recent = Get-ChildItem $gateRoot -Directory -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $TaskCount

$totalTasks = $recent.Count
$stepCounts = @()
$highAttemptTasks = @()
$stepFailurePatterns = @{}   # step -> list of {task, attempts, blocked_reason}

foreach ($td in $recent) {
    $sf = Join-Path $td.FullName "state.yaml"
    if (-not (Test-Path $sf)) { continue }
    $doneCount = 0
    $currentStep = ""
    $stepName = ""        # name of step block currently being read
    $stepAttempts = 0
    $stepReason = ""
    foreach ($l in (Get-Content $sf)) {
        # Root-level current_step line
        if ($l -match "^current_step:\s*`"?([\w-]+)`"?") { $currentStep = $matches[1] }
        if ($l.Trim() -match "status:\s*done") { $doneCount++ }
        # Step block header: "  verify:" or "  verify :" — flush previous block
        if ($l -match "^  (\w+):\s*$") {
            if ($stepName -ne "" -and $stepAttempts -gt 2) {
                $entry = @{ task=$td.Name; step=$stepName; attempts=$stepAttempts; blocked_reason=$stepReason }
                $highAttemptTasks += $entry
                if (-not $stepFailurePatterns.ContainsKey($stepName)) {
                    $stepFailurePatterns[$stepName] = @()
                }
                $stepFailurePatterns[$stepName] = @($stepFailurePatterns[$stepName]) + @($entry)
            }
            $stepName = $matches[1]
            $stepAttempts = 0
            $stepReason = ""
        }
        # Inside a step block: capture attempts and blocked_reason (order-agnostic)
        if ($stepName -ne "" -and $l -match "attempts:\s*(\d+)") {
            $stepAttempts = [int]$matches[1]
        }
        if ($stepName -ne "" -and $l -match "blocked_reason:\s*(.+)") {
            $stepReason = $matches[1].Trim() -replace '^[\"'']+|[\"'']+$', ''
        }
    }
    # Flush final step block at end of file
    if ($stepName -ne "" -and $stepAttempts -gt 2) {
        $entry = @{ task=$td.Name; step=$stepName; attempts=$stepAttempts; blocked_reason=$stepReason }
        $highAttemptTasks += $entry
        if (-not $stepFailurePatterns.ContainsKey($stepName)) {
            $stepFailurePatterns[$stepName] = @()
        }
        $stepFailurePatterns[$stepName] = @($stepFailurePatterns[$stepName]) + @($entry)
    }
    $stepCounts += $doneCount
}

$avgSteps = if ($stepCounts.Count -gt 0) { ($stepCounts | Measure-Object -Average).Average } else { 0 }

# ── Step 3: Deduplicate against existing genes ───────────────
# Read existing auto-generated genes to avoid duplicates
$existingGeneKeys = @{}   # "family:step:reason_normalized" -> geneId
if (Test-Path $dnaPath) {
    $inGene = $false
    $curId = ""; $curStep = ""; $curReason = ""; $curFamily = ""
    foreach ($line in Get-Content $dnaPath) {
        if ($line -match "^\s+- id:\s+(\w+-AUTO-\d+)") { $curId = $matches[1]; $inGene = $true }
        if ($inGene -and $line -match "^\s+name:\s+(\w+)_gate_blocked_(\w+)") {
            $curFamily = $matches[1]; $curStep = $matches[2]
        }
        if ($inGene -and $line -match "^\s+auto_reason:\s+(.+)") {
            $curReason = $matches[1].Trim() -replace '^[\"'']+|[\"'']+$', ''
            $key = "$($curFamily):$($curStep):$($curReason)"
            $existingGeneKeys[$key] = $curId
        }
        if ($inGene -and $line -match "^\w" -and $line -notmatch "^\s+") { $inGene = $false }
    }
}

# ── Step 4: Generate gene candidates from patterns ─────────────
$geneCandidates = @()

# Pattern → gene family mapping
$stepToFamily = @{
    "implement" = "CODE"
    "verify"    = "CODE"
    "review"    = "CODE"
    "close"     = "GENE"
}

# Track next ID per family for this batch (avoids same-run collisions)
$batchNextNum = @{}   # family -> next number to assign

foreach ($step in $stepFailurePatterns.Keys) {
    $patterns = $stepFailurePatterns[$step]
    if ($patterns.Count -lt 1) { continue }

    $family = $stepToFamily[$step]
    if (-not $family) { $family = "CODE" }

    # Build pattern description from blocked reasons
    $reasonSummary = ($patterns | ForEach-Object { $_.blocked_reason } | Where-Object { $_ -ne "" -and $_ -ne "null" -and $_ -ne "\" -and $_ -ne "null" } | ForEach-Object { $_.Trim() } | Select-Object -First 3) -join "; "
    if ([string]::IsNullOrWhiteSpace($reasonSummary)) {
        $reasonSummary = "step_blocked_repeatedly"
    }

    $taskList = ($patterns | ForEach-Object { $_.task } | Select-Object -First 3) -join ", "

    # Check if this exact pattern already has a gene
    $normReason = $reasonSummary -replace '["\\]', "" -replace "\s+", "_"
    $dedupKey = "$($family):$($step):$($normReason)"
    if ($existingGeneKeys.ContainsKey($dedupKey)) {
        Write-Output "[SKIP] Gene for '$step' reason='$reasonSummary' already exists as $($existingGeneKeys[$dedupKey])"
        continue
    }

    # Get next ID for this family (read from DNA + batch tracking)
    $nextNum = 1
    if (Test-Path $dnaPath) {
        $existingIds = @()
        foreach ($line in Get-Content $dnaPath) {
            if ($line -match "^  - id:\s+$family-AUTO-(\d+)") {
                $existingIds += [int]$matches[1]
            }
        }
        if ($existingIds.Count -gt 0) {
            $nextNum = ($existingIds | Measure-Object -Maximum).Maximum + 1
        }
    }
    # Apply batch-level increment (handles same-run ID collisions)
    if ($batchNextNum.ContainsKey($family)) {
        $nextNum = [Math]::Max($nextNum, $batchNextNum[$family])
    }
    $batchNextNum[$family] = $nextNum + 1

    # Pad to 3 digits: 1 -> "001", 12 -> "012"
    $paddedNum = "{0:000}" -f $nextNum
    $geneId = "$family-AUTO-$paddedNum"

    $candidate = @{
        id          = $geneId
        family      = $family
        step        = $step
        pattern     = "$($patterns.Count) tasks blocked on step '$step' (3+ attempts each)"
        reason      = $reasonSummary
        tasks       = $taskList
        trigger_kw  = @($step, "gate", "blocked", "attempts")
    }
    $geneCandidates += $candidate
}

# ── Step 5: Build gene YAML block ──────────────────────────────
function Build-GeneBlock($candidate) {
    $id = $candidate.id
    $name = "$($candidate.family)_gate_blocked_$($candidate.step)"
    $desc = "Gate system: step '$($candidate.step)' blocked 3+ times. Pattern: $($candidate.pattern). Reason: $($candidate.reason). Tasks: $($candidate.tasks). Auto-created by retro-analyze after $TaskCount-task scan."
    $triggers = ($candidate.trigger_kw | ForEach-Object { "`"$_`"" }) -join ", "

@"
  # AUTO-GENERATED GENE
  # Retro-analyze: $($candidate.pattern)
  - id: $id
    name: $name
    description: |
      $desc
    triggers: [$triggers]
    auto_generated: true
    auto_date: "$(Get-Date -Format o)"
    auto_reason: "$($candidate.reason)"
"@
}

# ── Step 6: Write genes to DNA.yaml ────────────────────────────
if ($WriteGenes -and $geneCandidates.Count -gt 0) {
    if ($DryRun) {
        Write-Output "[DRY RUN] Would write $($geneCandidates.Count) gene(s):"
        foreach ($c in $geneCandidates) {
            Write-Output "  - $($c.id): $($c.step) blocked (tasks: $($c.tasks))"
        }
    } else {
        # Read DNA.yaml
        if (-not (Test-Path $dnaPath)) {
            Write-Output "[ERROR] DNA.yaml not found at: $dnaPath"
            exit 1
        }
        $dnaLines = Get-Content $dnaPath

        # Find insertion point: after the LAST gene in the genes list
        # Genes are "- id:" lines with 2-space indent (YAML list items)
        $geneLineIndices = @()
        for ($i = 0; $i -lt $dnaLines.Count; $i++) {
            if ($dnaLines[$i] -match "^  - id:") {
                $geneLineIndices += $i
            }
        }
        if ($geneLineIndices.Count -eq 0) {
            Write-Output "[ERROR] No genes found in DNA.yaml - cannot determine insertion point"
            exit 1
        }
        # Find the end of the last gene block (last line with 4+ space indent after last - id:)
        $lastGeneStart = $geneLineIndices[-1]
        $insertIndex = $lastGeneStart
        for ($i = $lastGeneStart + 1; $i -lt $dnaLines.Count; $i++) {
            $line = $dnaLines[$i]
            # Gene fields are indented 4+ spaces (description, triggers, etc.)
            # When we hit a line with <4 spaces indent, the gene list ends
            if ($line -match "^    \S" -or $line -match "^    $") {
                $insertIndex = $i + 1
            } elseif ($line -match "^\S" -or ($line -match "^  \S" -and $line -notmatch "^  -")) {
                # Non-indented line or non-gene 2-space indent = end of gene list
                $insertIndex = $i
                break
            } else {
                $insertIndex = $i + 1
            }
        }

        # Build all gene blocks
        $geneBlocks = @()
        foreach ($c in $geneCandidates) {
            $geneBlocks += Build-GeneBlock $c
        }
        $geneBlockText = $geneBlocks -join "`n`n"

        # Insert gene blocks
        $newLines = @()
        for ($i = 0; $i -lt $insertIndex; $i++) {
            $newLines += $dnaLines[$i]
        }
        $newLines += $geneBlockText
        for ($i = $insertIndex; $i -lt $dnaLines.Count; $i++) {
            $newLines += $dnaLines[$i]
        }

        # Write back
        $newLines -join "`n" | Set-Content -Path $dnaPath -NoNewline -Encoding UTF8
        $genesWritten = $geneCandidates.Count

        Write-Output "[GENES WRITTEN] $genesWritten gene candidate(s) appended to DNA.yaml"
        foreach ($c in $geneCandidates) {
            Write-Output "  + $($c.id): $($c.step) blocked → $($c.pattern)"
        }
    }
}

# ── Step 7: Output JSON insights ────────────────────────────────
$insights = @{
    analyzed_at         = Get-Date -Format o
    total_tasks         = $totalTasks
    avg_steps_per_task  = [math]::Round($avgSteps, 2)
    high_attempt_tasks  = $highAttemptTasks
    blocked_count       = $highAttemptTasks.Count
    genes_written       = $genesWritten
    gene_candidates     = $geneCandidates
    recommendations     = @()
}

if ($highAttemptTasks.Count -gt 0) {
    $insights.recommendations += "Warning: $($highAttemptTasks.Count) tasks had steps with 3+ attempts"
}
if ($geneCandidates.Count -gt 0) {
    $insights.recommendations += "$($geneCandidates.Count) gene candidate(s) generated for DNA.yaml"
}

$output = $insights | ConvertTo-Json -Depth 5

if ($OutputFile) {
    $output | Set-Content -Path $OutputFile -NoNewline -Encoding UTF8
}

Write-Output $output

# Exit code: 0=analysis only, 2=genes written (signal for coordinator)
if ($genesWritten -gt 0) {
    exit 2
} else {
    exit 0
}
