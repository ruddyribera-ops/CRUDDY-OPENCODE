<#
.SYNOPSIS
    OpenCode configuration validator — 8-layer integrity check.
.DESCRIPTION
    Validates:
    1. opencode.json is valid JSON
    2. Agent completeness (.yaml + .md pairs)
    3. Skill integrity (SKILL.md frontmatter per active directory)
    4. Skill references (agent .md -> skills/X/SKILL.md)
    5. DNA.yaml COORD-003 <-> challenger rule keyword sync
    6. Rule files exist
    7. Referenced scripts exist
    8. File size anomalies (0-byte, suspicious)
.PARAMETER Quiet
    Only output failures, no success messages.
.PARAMETER Strict
    Fail on warnings as well as errors.
#>
param(
    [switch]$Quiet,
    [switch]$Strict
)

$configDir = "$env:USERPROFILE\.config\opencode"
$exitCode = 0
$checksPassed = 0
$checksFailed = 0
$warnings = 0

function Log-Result {
    param([string]$Check, [bool]$Passed, [string]$Detail)
    if ($Passed) {
        if (-not $Quiet) { Write-Host "  [PASS] $Check" -ForegroundColor Green }
        $script:checksPassed++
    } else {
        if ($Detail -match '^WARN') {
            Write-Host "  [WARN] $Check - $Detail" -ForegroundColor Yellow
            $script:warnings++
            if ($Strict) { $script:exitCode = 1 }
        } else {
            Write-Host "  [FAIL] $Check - $Detail" -ForegroundColor Red
            $script:checksFailed++
            $script:exitCode = 1
        }
    }
}

Write-Host "`n=== OpenCode Config Validator ===" -ForegroundColor Cyan
Write-Host "Config dir: $configDir`n" -ForegroundColor Gray

# ---- LAYER 1: opencode.json syntax ----
Write-Host "[1/8] Core config" -ForegroundColor Cyan
try {
    $json = Get-Content "$configDir\opencode.json" -Raw -ErrorAction Stop
    $null = $json | ConvertFrom-Json -ErrorAction Stop
    Log-Result "opencode.json" $true "valid JSON"
} catch {
    Log-Result "opencode.json" $false "parse error: $_"
}

# ---- LAYER 2: Agent completeness ----
Write-Host "[2/8] Agent completeness" -ForegroundColor Cyan
$agentDir = "$configDir\agents"
$yamlFiles = Get-ChildItem "$agentDir\*.yaml" -Name | ForEach-Object { $_ -replace '\.yaml$', '' }
$mdFiles = Get-ChildItem "$agentDir\*.md" -Name | ForEach-Object { $_ -replace '\.md$', '' } | Where-Object { $_ -ne 'SPECIALIZED_AGENTS' }
$schemaYaml = $false
$specDoc = $false
Get-ChildItem "$agentDir\*.yaml" -Name | Where-Object { $_ -eq 'agent-schema.yaml' } | ForEach-Object { $schemaYaml = $true }
Get-ChildItem "$agentDir\*.md" -Name | Where-Object { $_ -eq 'SPECIALIZED_AGENTS.md' } | ForEach-Object { $specDoc = $true }

# Each non-schema agent needs matching .md
foreach ($y in $yamlFiles) {
    if ($y -eq 'agent-schema') { continue }
    $hasMd = $y -in $mdFiles
    Log-Result "agent $y.yaml -> $y.md" $hasMd $(if (-not $hasMd) { "missing $y.md" } else { "" })
}
# Each .md (excluding SPECIALIZED_AGENTS) needs matching .yaml
foreach ($m in $mdFiles) {
    if ($m -eq 'SPECIALIZED_AGENTS' -or $m -eq 'main-coordinator') { continue }
    $hasYaml = $m -in $yamlFiles
    Log-Result "agent $m.md -> $m.yaml" $hasYaml $(if (-not $hasYaml) { "missing $m.yaml" } else { "" })
}
Log-Result "agent-schema.yaml present" $schemaYaml $(if (-not $schemaYaml) { "missing schema file" } else { "" })
Log-Result "SPECIALIZED_AGENTS.md present" $specDoc $(if (-not $specDoc) { "missing reference doc" } else { "" })

# ---- LAYER 3: Skill integrity ----
Write-Host "[3/8] Skill integrity" -ForegroundColor Cyan
$skillDir = "$configDir\skills"
$skillEntries = Get-ChildItem "$skillDir" -Directory | Where-Object { $_.Name -notin @('.archive', '_template') }
$missingSkill = 0
foreach ($s in $skillEntries) {
    $skillFile = "$skillDir\$($s.Name)\SKILL.md"
    if (-not (Test-Path $skillFile)) {
        Log-Result "skill $($s.Name)/SKILL.md" $false "file not found"
        $missingSkill++
        continue
    }
    $content = Get-Content $skillFile -Raw -ErrorAction SilentlyContinue
    if (-not $content -or $content.Trim().Length -eq 0) {
        Log-Result "skill $($s.Name)/SKILL.md" $false "empty file"
        continue
    }
    # Check for name frontmatter
    if ($content -notmatch '(?m)^name:\s*\S+') {
        Log-Result "skill $($s.Name)/SKILL.md" $false "missing 'name:' frontmatter"
        continue
    }
    # Check for description frontmatter
    if ($content -notmatch '(?m)^description:\s*.+') {
        Log-Result "skill $($s.Name)/SKILL.md" $false "WARN: missing 'description:' frontmatter"
        continue
    }
    Log-Result "skill $($s.Name)/SKILL.md" $true ""
}
if ($missingSkill -eq 0) { Log-Result "All $($skillEntries.Count) active skills have SKILL.md" $true "" }

# ---- LAYER 4: Skill references in agent .md files ----
Write-Host "[4/8] Skill references" -ForegroundColor Cyan
$agentMds = Get-ChildItem "$agentDir\*.md" | Where-Object { $_.Name -ne 'SPECIALIZED_AGENTS.md' }
$allGood = $true
foreach ($am in $agentMds) {
    $content = Get-Content $am.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $refs = [regex]::Matches($content, 'skills/(\w[\w-]*)/SKILL\.md')
    foreach ($r in $refs | Select-Object @{N='Skill';E={$_.Groups[1].Value}} -Unique) {
        $targetDir = "$skillDir\$($r.Skill)"
        $exists = Test-Path "$targetDir\SKILL.md"
        if (-not $exists) {
            Log-Result "$($am.Name) -> skills/$($r.Skill)/SKILL.md" $false "refers to non-existent skill"
            $allGood = $false
        }
    }
}
if ($allGood) { Log-Result "All skill references in agent .md files valid" $true "" }

# ---- LAYER 5: DNA.challenger keyword sync ----
Write-Host "[5/8] DNA.yaml <-> Challenger sync" -ForegroundColor Cyan
$dnaContent = Get-Content "$configDir\skills\DNA.yaml" -Raw -ErrorAction SilentlyContinue
$challengerContent = Get-Content "$configDir\agents\main-coordinator.md" -Raw -ErrorAction SilentlyContinue
if ($dnaContent -and $challengerContent) {
    # Extract COORD-003 triggers
    $coordSection = $dnaContent -split '(?=  - id: COORD-003)' | Select-Object -Skip 1 | Select-Object -First 1
    if ($coordSection) {
        $trigStart = $coordSection.IndexOf('triggers: [')
        $trigEnd = $coordSection.IndexOf(']', $trigStart)
        $dnaKeywords = if ($trigStart -ge 0 -and $trigEnd -gt $trigStart) {
            $coordSection.Substring($trigStart, $trigEnd - $trigStart + 1) -replace 'triggers:\s*\[', '' -replace '\]', '' -split ',' |
                ForEach-Object { $_.Trim().Trim("'""`t`n ") } | Where-Object { $_ -ne '' }
        } else { @() }

        # Extract core single-token keywords from challenger table
        $challengerTable = $challengerContent -split '### Trigger Keywords' | Select-Object -Skip 1 | Select-Object -First 1
        if ($challengerTable) {
            $tableEnd = $challengerTable.IndexOf('### Challenge Template')
            if ($tableEnd -ge 0) { $challengerTable = $challengerTable.Substring(0, $tableEnd) }
            $challKeywords = [regex]::Matches($challengerTable, '`([`\w\.\-\/\(\)]+)`') |
                ForEach-Object { $_.Groups[1].Value } | Where-Object {
                    $_ -notmatch '^\s*$' -and
                    $_ -notmatch '^[\.\/]' -and
                    $_ -notmatch '\.md$' -and
                    $_ -notmatch '^skills/' -and
                    $_.Length -ge 2
                } | Sort-Object -Unique

            # Check each challenger keyword has a near-match in DNA
            $missingFromDna = @()
            foreach ($ck in $challKeywords) {
                $normalized = $ck -replace '[@#:]', '' -replace ' ', '-'
                $found = $normalized -in $dnaKeywords -or
                    ($dnaKeywords | Where-Object { $normalized -eq $_ -or $normalized -like "$_-*" -or $_ -like "$normalized-*" }) -ne $null
                if (-not $found) {
                    $missingFromDna += $ck
                }
            }

            if ($missingFromDna.Count -eq 0) {
                Log-Result "COORD-003 covers all challenger keywords" $true "$($dnaKeywords.Count) DNA <=> $($challKeywords.Count) challenger"
            } else {
                $sampleCount = [Math]::Min(5, $missingFromDna.Count)
                $sample = $missingFromDna[0..($sampleCount-1)] -join ', '
                Log-Result "COORD-003 trigger coverage" $false "WARN: $($missingFromDna.Count) keywords missing from DNA triggers: $sample..."
            }
        }
    }
} else {
    Log-Result "DNA.yaml / challenger" $false "could not read files"
}

# ---- LAYER 6: Rule files ----
Write-Host "[6/8] Rule files" -ForegroundColor Cyan
$ruleDir = "$configDir\rules"
$referencedRules = @(
    'duties.md',
    'auto_memory.md',
    'M3-compensation.md',
    'browser_tool_decision.md'
)
$allRulesExist = $true
foreach ($r in $referencedRules) {
    $exists = Test-Path "$ruleDir\$r"
    if (-not $exists) {
        Log-Result "rules/$r" $false "not found"
        $allRulesExist = $false
    }
}
# Also check agent_rules subdirectory
$agentRulesDir = "$ruleDir\agent_rules"
$agentRuleFiles = @('env-security.md', 'review-frontend.md', 'review-reliability.md')
foreach ($r in $agentRuleFiles) {
    $exists = Test-Path "$agentRulesDir\$r"
    if (-not $exists) {
        Log-Result "rules/agent_rules/$r" $false "not found"
        $allRulesExist = $false
    }
}
if ($allRulesExist) {
    $ruleCount = (Get-ChildItem "$ruleDir\*.md" -Recurse).Count
    Log-Result "All referenced rules exist" $true "($ruleCount .md files)"
}

# ---- LAYER 7: Referenced scripts ----
Write-Host "[7/8] Referenced scripts" -ForegroundColor Cyan
$scriptDir = "$configDir\scripts"
$keyScripts = @(
    'track-tokens.ps1',
    'mail.py',
    'review-loop.py',
    'opensource.py',
    'check-rules.py',
    'rotate-session-log.ps1'
)
$hooksDir = "$scriptDir\hooks"
$keyHooks = @(
    'on-stop.ps1',
    'post-edit.ps1',
    'hook-startup.ps1'
)
$allScriptsExist = $true
foreach ($s in $keyScripts) {
    $exists = Test-Path "$scriptDir\$s"
    if (-not $exists) {
        Log-Result "scripts/$s" $false "not found"
        $allScriptsExist = $false
    }
}
foreach ($h in $keyHooks) {
    $exists = Test-Path "$hooksDir\$h"
    if (-not $exists) {
        Log-Result "scripts/hooks/$h" $false "not found"
        $allScriptsExist = $false
    }
}
if ($allScriptsExist) {
    $sCount = (Get-ChildItem "$scriptDir\*.ps1").Count
    $pyCount = (Get-ChildItem "$scriptDir\*.py").Count
    Log-Result "All referenced scripts exist" $true "($sCount .ps1, $pyCount .py)"
}

# ---- LAYER 8: File anomaly scan ----
Write-Host "[8/8] File anomaly scan (quick)" -ForegroundColor Cyan
$anomalies = 0
$checkDirs = @("$configDir\agents", "$configDir\skills", "$configDir\rules")
foreach ($dir in $checkDirs) {
    if (-not (Test-Path $dir)) { continue }
    $zeroByteFiles = Get-ChildItem "$dir\*" -File | Where-Object { $_.Length -eq 0 }
    foreach ($zf in $zeroByteFiles) {
        Log-Result "$($zf.FullName)" $false "WARN: 0-byte file"
        $anomalies++
    }
    $largeFiles = Get-ChildItem "$dir\*" -File -Recurse | Where-Object { $_.Extension -in '.md', '.ps1', '.py', '.yaml' -and $_.Length -gt 500000 }
    foreach ($lf in $largeFiles) {
        Log-Result "$($lf.FullName)" $false "WARN: unusually large ($($lf.Length / 1KB -as [int]) KB)"
        $anomalies++
    }
}
if ($anomalies -eq 0) { Log-Result "No file anomalies detected" $true "" }

# ---- Summary ----
Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "  PASS: $checksPassed" -ForegroundColor Green
Write-Host "  WARN: $warnings" -ForegroundColor Yellow
Write-Host "  FAIL: $checksFailed" -ForegroundColor Red
if ($exitCode -eq 0) { Write-Host "  STATUS: CONFIG INTEGRITY OK" -ForegroundColor Green }
else { Write-Host "  STATUS: ISSUES FOUND" -ForegroundColor Red }
Write-Host ""
exit $exitCode
