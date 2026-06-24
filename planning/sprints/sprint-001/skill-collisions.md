# Skill Name Collisions — Manual Review Required

Local: `~/.config/opencode/skills/`
External: `~/.claude/skills/` (and `~/.agents/skills/` if exists)

Both directories auto-load. When names match, BOTH descriptions surface in the system prompt. No silent shadowing.

All 84 collisions below have **identical** local and external descriptions — the files are byte-for-byte duplicates. This means either directory is equally canonical. The recommendation is KEEP_LOCAL for all since `~/.config/opencode/skills/` is the project-owned location.

| Skill Name | Local Path | External Path | Verdict |
|------------|------------|---------------|---------|
| account-manager | ~/.config/opencode/skills/account-manager/SKILL.md | ~/.claude/skills/account-manager/SKILL.md | KEEP_LOCAL |
| adaptive-ui | ~/.config/opencode/skills/adaptive-ui/SKILL.md | ~/.claude/skills/adaptive-ui/SKILL.md | KEEP_LOCAL |
| android-native-dev | ~/.config/opencode/skills/android-native-dev/SKILL.md | ~/.claude/skills/android-native-dev/SKILL.md | KEEP_LOCAL |
| api-patterns | ~/.config/opencode/skills/api-patterns/SKILL.md | ~/.claude/skills/api-patterns/SKILL.md | KEEP_LOCAL |
| app-scraper-tester | ~/.config/opencode/skills/app-scraper-tester/SKILL.md | ~/.claude/skills/app-scraper-tester/SKILL.md | KEEP_LOCAL |
| ask-questions-if-underspecified | ~/.config/opencode/skills/ask-questions-if-underspecified/SKILL.md | ~/.claude/skills/ask-questions-if-underspecified/SKILL.md | KEEP_LOCAL |
| authmd-registration | ~/.config/opencode/skills/authmd-registration/SKILL.md | ~/.claude/skills/authmd-registration/SKILL.md | KEEP_LOCAL |
| auth-patterns | ~/.config/opencode/skills/auth-patterns/SKILL.md | ~/.claude/skills/auth-patterns/SKILL.md | KEEP_LOCAL |
| autoresearch | ~/.config/opencode/skills/autoresearch/SKILL.md | ~/.claude/skills/autoresearch/SKILL.md | KEEP_LOCAL |
| batch-skill-enrichment | ~/.config/opencode/skills/batch-skill-enrichment/SKILL.md | ~/.claude/skills/batch-skill-enrichment/SKILL.md | KEEP_LOCAL |
| browser-robust | ~/.config/opencode/skills/browser-robust/SKILL.md | ~/.claude/skills/browser-robust/SKILL.md | KEEP_LOCAL |
| caveman | ~/.config/opencode/skills/caveman/SKILL.md | ~/.claude/skills/caveman/SKILL.md | KEEP_LOCAL |
| ci-cd-patterns | ~/.config/opencode/skills/ci-cd-patterns/SKILL.md | ~/.claude/skills/ci-cd-patterns/SKILL.md | KEEP_LOCAL |
| code-review | ~/.config/opencode/skills/code-review/SKILL.md | ~/.claude/skills/code-review/SKILL.md | KEEP_LOCAL |
| color-font-skill | ~/.config/opencode/skills/color-font-skill/SKILL.md | ~/.claude/skills/color-font-skill/SKILL.md | KEEP_LOCAL |
| cs-fundamentals | ~/.config/opencode/skills/cs-fundamentals/SKILL.md | ~/.claude/skills/cs-fundamentals/SKILL.md | KEEP_LOCAL |
| data-analysis | ~/.config/opencode/skills/data-analysis/SKILL.md | ~/.claude/skills/data-analysis/SKILL.md | KEEP_LOCAL |
| database-patterns | ~/.config/opencode/skills/database-patterns/SKILL.md | ~/.claude/skills/database-patterns/SKILL.md | KEEP_LOCAL |
| delivery-engineer | ~/.config/opencode/skills/delivery-engineer/SKILL.md | ~/.claude/skills/delivery-engineer/SKILL.md | KEEP_LOCAL |
| deployment-patterns | ~/.config/opencode/skills/deployment-patterns/SKILL.md | ~/.claude/skills/deployment-patterns/SKILL.md | KEEP_LOCAL |
| design | ~/.config/opencode/skills/design/SKILL.md | ~/.claude/skills/design/SKILL.md | KEEP_LOCAL |
| design-style-skill | ~/.config/opencode/skills/design-style-skill/SKILL.md | ~/.claude/skills/design-style-skill/SKILL.md | KEEP_LOCAL |
| desktop-manager | ~/.config/opencode/skills/desktop-manager/SKILL.md | ~/.claude/skills/desktop-manager/SKILL.md | KEEP_LOCAL |
| differential-review | ~/.config/opencode/skills/awesome-differential-review/SKILL.md | ~/.claude/skills/awesome-differential-review/SKILL.md | KEEP_LOCAL |
| evaluator-optimizer | ~/.config/opencode/skills/evaluator-optimizer/SKILL.md | ~/.claude/skills/evaluator-optimizer/SKILL.md | KEEP_LOCAL |
| flutter-dev | ~/.config/opencode/skills/flutter-dev/SKILL.md | ~/.claude/skills/flutter-dev/SKILL.md | KEEP_LOCAL |
| frontend-design | ~/.config/opencode/skills/frontend-design/SKILL.md | ~/.claude/skills/frontend-design/SKILL.md | KEEP_LOCAL |
| frontend-dev | ~/.config/opencode/skills/frontend-dev/SKILL.md | ~/.claude/skills/frontend-dev/SKILL.md | KEEP_LOCAL |
| fullstack-dev | ~/.config/opencode/skills/fullstack-dev/SKILL.md | ~/.claude/skills/fullstack-dev/SKILL.md | KEEP_LOCAL |
| gif-sticker-maker | ~/.config/opencode/skills/gif-sticker-maker/SKILL.md | ~/.claude/skills/gif-sticker-maker/SKILL.md | KEEP_LOCAL |
| git-workflow | ~/.config/opencode/skills/git-workflow/SKILL.md | ~/.claude/skills/git-workflow/SKILL.md | KEEP_LOCAL |
| hermes-agent | ~/.config/opencode/skills/hermes-agent/SKILL.md | ~/.claude/skills/hermes-agent/SKILL.md | KEEP_LOCAL |
| hermes-integration | ~/.config/opencode/skills/hermes-integration/SKILL.md | ~/.claude/skills/hermes-integration/SKILL.md | KEEP_LOCAL |
| investigate | ~/.config/opencode/skills/investigate/SKILL.md | ~/.claude/skills/investigate/SKILL.md | KEEP_LOCAL |
| ios-application-dev | ~/.config/opencode/skills/ios-application-dev/SKILL.md | ~/.claude/skills/ios-application-dev/SKILL.md | KEEP_LOCAL |
| js-modern-patterns | ~/.config/opencode/skills/js-modern-patterns/SKILL.md | ~/.claude/skills/js-modern-patterns/SKILL.md | KEEP_LOCAL |
| jwt-security | ~/.config/opencode/skills/jwt-security/SKILL.md | ~/.claude/skills/jwt-security/SKILL.md | KEEP_LOCAL |
| karpathy-guidelines | ~/.config/opencode/skills/karpathy-guidelines/SKILL.md | ~/.claude/skills/karpathy-guidelines/SKILL.md | KEEP_LOCAL |
| lps-sis-excel-etl | ~/.config/opencode/skills/lps-sis-excel-etl/SKILL.md | ~/.claude/skills/lps-sis-excel-etl/SKILL.md | KEEP_LOCAL |
| memory-retrieval | ~/.config/opencode/skills/memory-retrieval/SKILL.md | ~/.claude/skills/memory-retrieval/SKILL.md | KEEP_LOCAL |
| minimax-docx | ~/.config/opencode/skills/minimax-docx/SKILL.md | ~/.claude/skills/minimax-docx/SKILL.md | KEEP_LOCAL |
| minimax-multimodal-toolkit | ~/.config/opencode/skills/minimax-multimodal-toolkit/SKILL.md | ~/.claude/skills/minimax-multimodal-toolkit/SKILL.md | KEEP_LOCAL |
| minimax-music-gen | ~/.config/opencode/skills/minimax-music-gen/SKILL.md | ~/.claude/skills/minimax-music-gen/SKILL.md | KEEP_LOCAL |
| minimax-music-playlist | ~/.config/opencode/skills/minimax-music-playlist/SKILL.md | ~/.claude/skills/minimax-music-playlist/SKILL.md | KEEP_LOCAL |
| minimax-pdf | ~/.config/opencode/skills/minimax-pdf/SKILL.md | ~/.claude/skills/minimax-pdf/SKILL.md | KEEP_LOCAL |
| minimax-xlsx | ~/.config/opencode/skills/minimax-xlsx/SKILL.md | ~/.claude/skills/minimax-xlsx/SKILL.md | KEEP_LOCAL |
| mmx-cli | ~/.config/opencode/skills/mmx-cli/SKILL.md | ~/.claude/skills/mmx-cli/SKILL.md | KEEP_LOCAL |
| msoffice-tools | ~/.config/opencode/skills/msoffice-tools/SKILL.md | ~/.claude/skills/msoffice-tools/SKILL.md | KEEP_LOCAL |
| no-silent-failure | ~/.config/opencode/skills/no-silent-failure/SKILL.md | ~/.claude/skills/no-silent-failure/SKILL.md | KEEP_LOCAL |
| ocr-tools | ~/.config/opencode/skills/ocr-tools/SKILL.md | ~/.claude/skills/ocr-tools/SKILL.md | KEEP_LOCAL |
| office-hours | ~/.config/opencode/skills/office-hours/SKILL.md | ~/.claude/skills/office-hours/SKILL.md | KEEP_LOCAL |
| opencode-delegation | ~/.config/opencode/skills/opencode-delegation/SKILL.md | ~/.claude/skills/opencode-delegation/SKILL.md | KEEP_LOCAL |
| opensource | ~/.config/opencode/skills/opensource/SKILL.md | ~/.claude/skills/opensource/SKILL.md | KEEP_LOCAL |
| password-security | ~/.config/opencode/skills/password-security/SKILL.md | ~/.claude/skills/password-security/SKILL.md | KEEP_LOCAL |
| performance-optimization | ~/.config/opencode/skills/performance-optimization/SKILL.md | ~/.claude/skills/performance-optimization/SKILL.md | KEEP_LOCAL |
| ppt-editing-skill | ~/.config/opencode/skills/ppt-editing-skill/SKILL.md | ~/.claude/skills/ppt-editing-skill/SKILL.md | KEEP_LOCAL |
| ppt-orchestra-skill | ~/.config/opencode/skills/ppt-orchestra-skill/SKILL.md | ~/.claude/skills/ppt-orchestra-skill/SKILL.md | KEEP_LOCAL |
| pptx-generator | ~/.config/opencode/skills/pptx-generator/SKILL.md | ~/.claude/skills/pptx-generator/SKILL.md | KEEP_LOCAL |
| progressive-disclosure | ~/.config/opencode/skills/progressive-disclosure/SKILL.md | ~/.claude/skills/progressive-disclosure/SKILL.md | KEEP_LOCAL |
| project-manager | ~/.config/opencode/skills/project-manager/SKILL.md | ~/.claude/skills/project-manager/SKILL.md | KEEP_LOCAL |
| pr-review | ~/.config/opencode/skills/pr-review/SKILL.md | ~/.claude/skills/pr-review/SKILL.md | KEEP_LOCAL |
| python-patterns | ~/.config/opencode/skills/python-patterns/SKILL.md | ~/.claude/skills/python-patterns/SKILL.md | KEEP_LOCAL |
| qa-engineer | ~/.config/opencode/skills/qa-engineer/SKILL.md | ~/.claude/skills/qa-engineer/SKILL.md | KEEP_LOCAL |
| react-native-dev | ~/.config/opencode/skills/react-native-dev/SKILL.md | ~/.claude/skills/react-native-dev/SKILL.md | KEEP_LOCAL |
| realtime-patterns | ~/.config/opencode/skills/realtime-patterns/SKILL.md | ~/.claude/skills/realtime-patterns/SKILL.md | KEEP_LOCAL |
| review-loop | ~/.config/opencode/skills/review-loop/SKILL.md | ~/.claude/skills/review-loop/SKILL.md | KEEP_LOCAL |
| rosariosis-codebase-inspection | ~/.config/opencode/skills/rosariosis-codebase-inspection/SKILL.md | ~/.claude/skills/rosariosis-codebase-inspection/SKILL.md | KEEP_LOCAL |
| secrets-management | ~/.config/opencode/skills/secrets-management/SKILL.md | ~/.claude/skills/secrets-management/SKILL.md | KEEP_LOCAL |
| security-basics | ~/.config/opencode/skills/security-basics/SKILL.md | ~/.claude/skills/security-basics/SKILL.md | KEEP_LOCAL |
| shader-dev | ~/.config/opencode/skills/shader-dev/SKILL.md | ~/.claude/skills/shader-dev/SKILL.md | KEEP_LOCAL |
| skill-learning | ~/.config/opencode/skills/skill-learning/SKILL.md | ~/.claude/skills/skill-learning/SKILL.md | KEEP_LOCAL |
| slide-making-skill | ~/.config/opencode/skills/slide-making-skill/SKILL.md | ~/.claude/skills/slide-making-skill/SKILL.md | KEEP_LOCAL |
| solutions-architect | ~/.config/opencode/skills/solutions-architect/SKILL.md | ~/.claude/skills/solutions-architect/SKILL.md | KEEP_LOCAL |
| sql-safety | ~/.config/opencode/skills/sql-safety/SKILL.md | ~/.claude/skills/sql-safety/SKILL.md | KEEP_LOCAL |
| subagent-driven-development | ~/.config/opencode/skills/subagent-driven-development/SKILL.md | ~/.claude/skills/subagent-driven-development/SKILL.md | KEEP_LOCAL |
| systematic-debugging | ~/.config/opencode/skills/systematic-debugging/SKILL.md | ~/.claude/skills/systematic-debugging/SKILL.md | KEEP_LOCAL |
| tech-lead | ~/.config/opencode/skills/tech-lead/SKILL.md | ~/.claude/skills/tech-lead/SKILL.md | KEEP_LOCAL |
| test-driven-development | ~/.config/opencode/skills/test-driven-development/SKILL.md | ~/.claude/skills/test-driven-development/SKILL.md | KEEP_LOCAL |
| testing-standards | ~/.config/opencode/skills/testing-standards/SKILL.md | ~/.claude/skills/testing-standards/SKILL.md | KEEP_LOCAL |
| textbook-to-pptx | ~/.config/opencode/skills/textbook-to-pptx/SKILL.md | ~/.claude/skills/textbook-to-pptx/SKILL.md | KEEP_LOCAL |
| ui-design | ~/.config/opencode/skills/ui-design/SKILL.md | ~/.claude/skills/ui-design/SKILL.md | KEEP_LOCAL |
| vision-analysis | ~/.config/opencode/skills/vision-analysis/SKILL.md | ~/.claude/skills/vision-analysis/SKILL.md | KEEP_LOCAL |
| webapp-testing | ~/.config/opencode/skills/webapp-testing/SKILL.md | ~/.claude/skills/webapp-testing/SKILL.md | KEEP_LOCAL |
| writing-skills | ~/.config/opencode/skills/writing-skills/SKILL.md | ~/.claude/skills/writing-skills/SKILL.md | KEEP_LOCAL |

## Recommendation

**KEEP_LOCAL for all 84 collisions.** The local `~/.config/opencode/skills/` directory is project-owned and version-controlled. The external `~/.claude/skills/` appears to be a mirror. Since descriptions are identical, there is no content difference — the user can safely delete the external copies to reduce context-window noise.

## Action required from user

To clean up collisions (optional but recommended):
```powershell
# Dry run — list what would be deleted
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Recurse -Filter SKILL.md | ForEach-Object {
  $name = ($_ | Get-Content -Raw) -match '(?m)^name:\s*(\S+)'; $matches[1]
  if (Test-Path "$env:USERPROFILE\.config\opencode\skills\$name\SKILL.md") {
    Write-Host "Would delete: $($_.FullName)"
  }
}

# Actual deletion (uncomment when ready)
# Get-ChildItem "$env:USERPROFILE\.claude\skills" -Recurse -Filter SKILL.md | ForEach-Object {
#   $name = ($_ | Get-Content -Raw) -match '(?m)^name:\s*(\S+)'; $matches[1]
#   if (Test-Path "$env:USERPROFILE\.config\opencode\skills\$name\SKILL.md") {
#     Remove-Item $_.FullName -Force
#     Write-Host "Deleted: $($_.FullName)"
#   }
# }
```

Generated: 2026-06-24T08:26:46Z