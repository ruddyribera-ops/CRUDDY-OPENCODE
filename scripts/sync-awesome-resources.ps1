# sync-awesome-resources.ps1
# Synchronizes skill resource tables with curated awesome-lists or community repos

param(
    [string]$SkillName,
    [string]$SourceUrl = "https://raw.githubusercontent.com/ruddyribera-ops/opencode-power-setup/main/resources/mapping.json"
)

$skillsDir = "$env:USERPROFILE\.config\opencode\skills"

if ($SkillName) {
    $targetSkill = Join-Path $skillsDir "$SkillName\SKILL.md"
    if (!(Test-Path $targetSkill)) {
        Write-Error "Skill not found: $SkillName"
        exit 1
    }
    
    Write-Host "Syncing resources for $SkillName from $SourceUrl..."
    # Placeholder for actual fetch and frontmatter/table update logic
    # In a real scenario, this would use Invoke-RestMethod and regex to update the SKILL.md
    Write-Host "Feature coming soon: Automated table patching from upstream."
} else {
    Write-Host "Usage: ./sync-awesome-resources.ps1 -SkillName <name>"
    Write-Host "Available for all 56 skills."
}
