# gene-approve.ps1
# Lists, approves, or rejects auto-generated genes in DNA.yaml
# Exit codes: 0=success, 1=error, 2=gene not found
param(
    [switch]$List,                # List all auto-generated genes
    [string]$Approve = "",        # Gene ID to approve
    [string]$Reject = "",         # Gene ID to reject
    [switch]$Pending,             # With -List: only show pending (unapproved) genes
    [switch]$All,                 # With -List: show all auto genes including approved/rejected
    [string]$DnaPath = ""         # Override DNA.yaml path
)
$ErrorActionPreference = "Stop"

# Default DNA path
if (-not $DnaPath) {
    $DnaPath = "$env:CONFIG\skills\DNA.yaml"
}

if (-not (Test-Path $DnaPath)) {
    Write-Output "[ERROR] DNA.yaml not found at: $DnaPath"
    exit 1
}

# -- Parse DNA.yaml into gene blocks -----------------------------
$lines = Get-Content $DnaPath
$genes = @()         # List of @{id, startLine, endLine, status, family, step, reason, date}
$inGenes = $false
$currentGene = $null
$geneStart = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    # Detect start of genes: list
    if ($line -match "^genes:\s*$") { $inGenes = $true; continue }
    if (-not $inGenes) { continue }

    # New gene block: "  - id: SOMETHING"
    if ($line -match "^  - id:\s+(.+)") {
        # Save previous gene if exists
        if ($currentGene) {
            $currentGene.endLine = $i - 1
            $genes += $currentGene
        }
        $currentGene = @{
            id         = $matches[1].Trim()
            startLine  = $i
            endLine    = -1
            status     = "manual"   # default: manually written
            name       = ""
            reason     = ""
            date       = ""
            family     = ""
            step       = ""
        }
        $geneStart = $i
        continue
    }

    # If we have a current gene, capture fields
    if ($currentGene) {
        if ($line -match "^\s+name:\s+(\w+)_gate_blocked_(\w+)") {
            $currentGene.family = $matches[1]
            $currentGene.step   = $matches[2]
            $currentGene.name   = $line -replace "^\s+name:\s+", ""
        }
        if ($line -match "^\s+auto_reason:\s+(.+)") {
            $currentGene.reason = $matches[1].Trim() -replace '^[\"'']+|[\"'']+$', ''
        }
        if ($line -match "^\s+auto_date:\s+(.+)") {
            $currentGene.date = $matches[1].Trim() -replace '^[\"'']+|[\"'']+$', ''
        }
        if ($line -match "^\s+auto_generated:\s+true") {
            $currentGene.status = "pending"
        }
        if ($line -match "^\s+auto_approved:\s+true") {
            $currentGene.status = "approved"
        }
        if ($line -match "^\s+auto_rejected:\s+true") {
            $currentGene.status = "rejected"
        }
        # End of genes list: any non-indented line (not a comment) OR 2-space line that isn't a list item
        if (($line -match "^\S" -and $line -notmatch "^\s*#") -or ($line -match "^  \S" -and $line -notmatch "^  -" -and $line -notmatch "^\s*#")) {
            $currentGene.endLine = $i - 1
            $genes += $currentGene
            $currentGene = $null
            $inGenes = $false
        }
    }
}
# Save the last gene if file ended without another section
if ($currentGene) {
    $currentGene.endLine = $lines.Count - 1
    $genes += $currentGene
}

# -- Action: List ------------------------------------------------
if ($List) {
    $autoGenes = @($genes | Where-Object { $_.status -ne "manual" })
    if ($Pending -and -not $All) {
        $autoGenes = @($autoGenes | Where-Object { $_.status -eq "pending" })
    }

    if ($autoGenes.Count -eq 0) {
        if ($Pending) {
            Write-Output "No pending auto-generated genes."
        } else {
            Write-Output "No auto-generated genes found."
        }
        exit 0
    }

    Write-Output "=== Auto-Generated Genes ==="
    Write-Output ""
    foreach ($g in $autoGenes) {
        $statusIcon = switch ($g.status) {
            "pending"  { "[PENDING] " }
            "approved" { "[APPROVED] " }
            "rejected" { "[REJECTED] " }
            default    { "[UNKNOWN]  " }
        }
        Write-Output "$statusIcon$($g.id)"
        Write-Output "  Step:   $($g.step)"
        Write-Output "  Reason: $($g.reason)"
        if ($g.date) {
            Write-Output "  Date:   $($g.date)"
        }
        Write-Output ""
    }

    # Summary
    $counts = @{
        pending  = @($autoGenes | Where-Object { $_.status -eq "pending" }).Count
        approved = @($autoGenes | Where-Object { $_.status -eq "approved" }).Count
        rejected = @($autoGenes | Where-Object { $_.status -eq "rejected" }).Count
    }
    Write-Output "=== Summary ==="
    Write-Output "Pending:  $($counts.pending)"
    Write-Output "Approved: $($counts.approved)"
    Write-Output "Rejected: $($counts.rejected)"
    exit 0
}

# -- Action: Approve ---------------------------------------------
if ($Approve) {
    $target = $genes | Where-Object { $_.id -eq $Approve } | Select-Object -First 1
    if (-not $target) {
        Write-Output "[ERROR] Gene not found: $Approve"
        Write-Output "Use -List to see available genes."
        exit 2
    }
    if ($target.status -eq "approved") {
        Write-Output "[SKIP] Gene $Approve is already approved"
        exit 0
    }

    # Insert approval fields at end of gene block (before next gene or section)
    $newLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $newLines += $lines[$i]
        if ($i -eq $target.endLine) {
            $dateStr = Get-Date -Format o
            $newLines += "    auto_approved: true"
            $newLines += ('    approved_date: "' + $dateStr + '"')
            $newLines += '    approved_by: "evolution-agent"'
        }
    }
    $newLines -join "`n" | Set-Content -Path $DnaPath -NoNewline -Encoding UTF8
    Write-Output "[APPROVED] Gene $Approve marked as approved"
    exit 0
}

# -- Action: Reject ----------------------------------------------
if ($Reject) {
    $target = $genes | Where-Object { $_.id -eq $Reject } | Select-Object -First 1
    if (-not $target) {
        Write-Output "[ERROR] Gene not found: $Reject"
        Write-Output "Use -List to see available genes."
        exit 2
    }
    if ($target.status -eq "rejected") {
        Write-Output "[SKIP] Gene $Reject is already rejected"
        exit 0
    }

    # Insert rejection fields at end of gene block
    $newLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $newLines += $lines[$i]
        if ($i -eq $target.endLine) {
            $dateStr = Get-Date -Format o
            $newLines += "    auto_rejected: true"
            $newLines += ('    rejected_date: "' + $dateStr + '"')
            $newLines += '    rejected_by: "evolution-agent"'
        }
    }
    $newLines -join "`n" | Set-Content -Path $DnaPath -NoNewline -Encoding UTF8
    Write-Output "[REJECTED] Gene $Reject marked as rejected"
    exit 0
}

# -- No action specified -----------------------------------------
Write-Output "gene-approve.ps1 - manage auto-generated genes"
Write-Output ""
Write-Output "Usage:"
Write-Output "  -List                  List all auto-generated genes"
Write-Output "  -List -Pending         List only pending (unapproved) genes"
Write-Output "  -List -All             List all auto genes including approved/rejected"
Write-Output '  -Approve [gene-id]     Mark a gene as approved'
Write-Output '  -Reject [gene-id]      Mark a gene as rejected'
Write-Output ""
Write-Output "Examples:"
Write-Output "  powershell -File gene-approve.ps1 -List -Pending"
Write-Output "  powershell -File gene-approve.ps1 -Approve CODE-AUTO-001"
Write-Output "  powershell -File gene-approve.ps1 -Reject CODE-AUTO-002"
exit 0
