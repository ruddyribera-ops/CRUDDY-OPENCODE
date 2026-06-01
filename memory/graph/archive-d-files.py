import subprocess

result = subprocess.run(['git', 'status', '--short', 'skills/.archive/'], capture_output=True, text=True, cwd='.')
lines = [l.strip() for l in result.stdout.strip().split('\n') if l.strip()]
d_files = [l[3:] for l in lines if l.startswith('D ')]
m_files = [l[3:] for l in lines if l.startswith('M ')]
print('D files:', len(d_files))
print('M files:', len(m_files))
print()
if d_files:
    print('=== D files (will stage with git rm) ===')
    for f in sorted(d_files):
        print(' ', f)
    print()
    # Stage with git rm
    cmd = ['git', 'rm'] + sorted(d_files)
    r = subprocess.run(cmd, capture_output=True, text=True, cwd='.')
    print('git rm returncode:', r.returncode)
    if r.stdout: print('stdout:', r.stdout[:300])
    if r.stderr: print('stderr:', r.stderr[:300])
else:
    print('No D files to stage')