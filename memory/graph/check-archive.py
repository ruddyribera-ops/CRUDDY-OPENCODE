import subprocess, os

result = subprocess.run(['git', 'status', '--short', 'skills/.archive/'], capture_output=True, text=True, cwd='.')
status_lines = [l.strip() for l in result.stdout.strip().split('\n') if l.strip()]

d_in_archive = [l[3:] for l in status_lines if l.startswith('D ')]
m_in_archive = [l[3:] for l in status_lines if l.startswith('M ')]

print('=== .archive/ DELETED (D) ===')
print('Count:', len(d_in_archive))
for f in sorted(d_in_archive):
    disk_exists = os.path.exists(f)
    print('  ' + ('EXISTS' if disk_exists else 'GONE ') + ': ' + f)

print()
print('=== .archive/ MODIFIED (M) - sample 5 ===')
print('Count:', len(m_in_archive))
for f in sorted(m_in_archive)[:5]:
    print('  MODIFIED: ' + f)