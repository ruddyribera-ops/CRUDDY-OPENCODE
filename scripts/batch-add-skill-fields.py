# D:\Users\Windows\.config\opencode\scripts\batch-add-skill-fields.py
# Adds triggers and applies_to fields to skill SKILL.md frontmatter
# that are missing them (tier-2 warnings from validate-skills.ts)
import os
import re

_config_root = os.environ.get('OPENCODE_CONFIG_HOME') or os.path.join(os.environ.get('USERPROFILE', ''), '.config', 'opencode') or os.path.join(os.environ.get('HOME', ''), '.config', 'opencode')
SKILLS_DIR = os.path.join(_config_root, 'skills')

# Skills needing triggers AND applies_to (from validate-skills.ts output)
needs_both = [
    'android-native-dev', 'api-patterns', 'autoresearch',
    'awesome-ask-questions-if-underspecified', 'codemap', 'cost-tracking',
    'cs-fundamentals', 'customize-opencode', 'database-patterns',
    'deployment-patterns', 'differential-review', 'evaluation', 'flutter-dev',
    'investigate', 'ios-application-dev', 'js-modern-patterns',
    'karpathy-guidelines', 'no-silent-failure', 'ocr-tools',
    'performance-optimization', 'production-readiness', 'python-patterns',
    'react-native-dev', 'secure-coding', 'security-basics', 'sql-safety',
    'superpowers-subagent-driven-development', 'superpowers-writing-skills',
    'systematic-debugging', 'testing-and-debugging', 'tracing', 'ui-design',
    'webapp-testing'
]

# Skills needing applies_to only (tier-2 partial)
needs_applies_only = [
    'awesome-office-hours'
]

all_needy = needs_both + needs_applies_only

def derive_triggers(skill_name, description=''):
    """Derive trigger phrases from skill name and description."""
    # Strip prefixes
    display = skill_name.replace('awesome-', '').replace('-', ' ')

    # Common trigger patterns
    triggers = [
        skill_name,
        display,
        f"when to use {display}",
        f"how to {display}",
        f"{display} examples",
        f"{display} pattern",
    ]
    return triggers

def process_skill(skill_name, need_triggers, need_applies):
    skill_dir = os.path.join(SKILLS_DIR, skill_name)
    skill_md = os.path.join(skill_dir, 'SKILL.md')

    if not os.path.exists(skill_md):
        print(f"SKIP: {skill_name} — no SKILL.md")
        return False

    with open(skill_md, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find frontmatter boundaries
    fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        print(f"SKIP: {skill_name} — no frontmatter")
        return False

    fm = fm_match.group(1)
    fm_start = fm_match.start()
    fm_end = fm_match.end()

    # Extract description from frontmatter
    desc_match = re.search(r'description:\s*["\']?(.+?)(?:["\']?\s*$)', fm, re.MULTILINE)
    description = desc_match.group(1)[:200] if desc_match else skill_name

    # Build new fields
    new_fields = []

    if need_triggers:
        triggers = derive_triggers(skill_name, description)
        new_fields.append('triggers:')
        for t in triggers:
            new_fields.append(f'  - "{t}"')

    if need_applies:
        new_fields.append('applies_to:')
        new_fields.append('  - "main-coordinator"')

    if not new_fields:
        return False

    # Append new fields before the closing ---
    new_fm = fm.rstrip() + '\n' + '\n'.join(new_fields) + '\n'
    new_content = content[:fm_start] + '---\n' + new_fm + '---\n' + content[fm_end:]

    with open(skill_md, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"Updated: {skill_name}")
    return True

def main():
    updated = 0
    for skill_name in all_needy:
        need_triggers = skill_name in needs_both
        need_applies = True
        if process_skill(skill_name, need_triggers, need_applies):
            updated += 1
    print(f"\nTotal skills updated: {updated}")

if __name__ == '__main__':
    main()
