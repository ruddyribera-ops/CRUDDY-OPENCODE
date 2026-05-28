import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("course_13443.html", "r", encoding="utf-8") as f:
    content = f.read()

# Find the section-0 div completely
section_match = re.search(r'<li[^>]*id="section-0"[^>]*>(.*?)</li>', content, re.DOTALL | re.I)
if section_match:
    section_html = section_match.group(1)
    print("Section 0 HTML (first 3000 chars):")
    print(section_html[:3000])
else:
    print("Section-0 not found as li")
    # Maybe it's a div
    section_match = re.search(r'<div[^>]*id="section-0"[^>]*>(.*?)</div>', content, re.DOTALL | re.I)
    if section_match:
        print("Found as div:")
        print(section_match.group(1)[:3000])

print("\n\n=== ALL DIV CLASSES ===")
all_div_classes = re.findall(r'<div[^>]*class="([^"]+)"', content)
unique_classes = set()
for c in all_div_classes:
    for part in c.split():
        if len(part) > 3:
            unique_classes.add(part)
for c in sorted(unique_classes):
    print(f"  {c}")
