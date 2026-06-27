# run-plan-mode.ps1
# Plan Mode for vague tasks — invoked by SESSION-005 gene.
# Shows user a structured plan and waits for approval before proceeding.
#
# Usage: powershell -File run-plan-mode.ps1 -TaskDescription "<task>" -ComplexityScore "<score>"
#
# Exit codes:
#   0 = approved, proceed
#   1 = user aborted
#   2 = plan displayed, awaiting user input (interactive mode)

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskDescription,

    [string]$ComplexityScore = "1"
)

$configDir = "$env:USERPROFILE\.config\opencode"
$planDir = "$configDir\memory\plans"

# Generate a plan based on the task description
$planId = "plan-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$planFile = Join-Path $planDir "$planId.md"

if (-not (Test-Path $planDir)) {
    New-Item -ItemType Directory -Path $planDir -Force | Out-Null
}

$plan = @"
# Plan: $TaskDescription

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Complexity Score:** $ComplexityScore
**Plan ID:** $planId

## Understanding
- Task: $TaskDescription
- Estimated complexity: $ComplexityScore/10

## Approach

1. **Discovery** — clarify intent with 1-2 questions if scope unclear
2. **Plan of Action** — break into 3-5 sub-tasks
3. **Implementation** — execute via code-builder with POA + audit
4. **Verification** — tests pass + lint clean + review PASS
5. **Report** — consolidated summary

## Risks
- Scope creep (mitigated by POA scope lock)
- Hidden dependencies (mitigated by /analyze before implement)
- Incomplete context (mitigated by Compaction survival hook)

## Approval Required
This plan is awaiting your approval. Reply with:
- "yes" or "proceed" — implement
- "no" or "abort" — cancel
- Specific feedback — refine the plan
"@

$plan | Out-File -FilePath $planFile -Encoding UTF8

Write-Host ""
Write-Host "=== PLAN MODE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host $plan
Write-Host ""
Write-Host "Plan saved to: $planFile" -ForegroundColor Gray
Write-Host ""

# In non-interactive mode (called by SESSION-005 gene), exit 2 to signal "awaiting approval"
# In interactive mode, prompt user
if ($env:OPENCODE_NON_INTERACTIVE -eq "1") {
    Write-Host "[plan-mode] Non-interactive mode — plan generated, awaiting coordinator approval" -ForegroundColor Yellow
    exit 2
}

$response = Read-Host "Approve this plan? (yes/no/refine)"
switch -Regex ($response.ToLower()) {
    "^(yes|y|proceed|p)$" {
        Write-Host "[plan-mode] Approved — proceeding" -ForegroundColor Green
        exit 0
    }
    "^(no|n|abort|cancel)$" {
        Write-Host "[plan-mode] Aborted by user" -ForegroundColor Red
        exit 1
    }
    default {
        Write-Host "[plan-mode] Plan refined with feedback" -ForegroundColor Yellow
        exit 2
    }
}
