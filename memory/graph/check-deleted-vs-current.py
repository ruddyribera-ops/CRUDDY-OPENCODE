import subprocess, os

# Get D files from skills/.archive/
result = subprocess.run(['git', 'status', '--short', 'skills/.archive/'], capture_output=True, text=True, cwd='.')
d_entries = [(l[0], l[3:]) for l in result.stdout.strip().split('\n') if l.strip() and l[0] in ('D', ' ')]
d_files = [path for status, path in d_entries if status == 'D']

print('=== 37 DELETED from .archive (D status) ===')
deleted_skills = sorted(set('/'.join(p.split('/')[:2]) for p in d_files))
for s in deleted_skills:
    print(' ', s)
print(f'Total: {len(deleted_skills)} skills')

print()

# What's currently in skills/ (top-level dirs, excluding .archive)
skills_path = 'skills'
all_skills = sorted([d for d in os.listdir(skills_path) if os.path.isdir(os.path.join(skills_path, d)) and d != '.archive'])
print(f'=== Current skills/ directory: {len(all_skills)} skills ===')
for s in all_skills:
    print(' ', s)

print()

# Overlap
deleted_basenames = set(s.split('/')[-1] for s in deleted_skills)
current_basenames = set(all_skills)
overlap = deleted_basenames & current_basenames
only_deleted = deleted_basenames - current_basenames

print(f'=== Overlap with current skills/ ===')
print(f'Deleted skills that STILL EXIST in skills/: {len(overlap)}')
for s in sorted(overlap):
    print(' ', s)
print()
print(f'Deleted skills that are GONE from skills/: {len(only_deleted)}')
for s in sorted(only_deleted):
    print(' ', s)