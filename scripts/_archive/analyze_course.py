import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("course_13443.html", "r", encoding="utf-8") as f:
    content = f.read()

print(f"File size: {len(content)} chars")

# Find headers
headers = re.findall(r'<h[23][^>]*>([^<]+)</h[23]>', content)
print(f"\nHeaders ({len(headers)}):")
for h in headers[:30]:
    print(f"  {h.strip()}")

# Check main content area
for marker in ["region-main", "course-content", "maincontent", "section"]:
    count = len(re.findall(marker, content, re.I))
    print(f"  '{marker}' refs: {count}")

# Look for section-like divs
section_divs = re.findall(r'<div[^>]*class="[^"]*topic[^"]*"[^>]*>', content, re.I)
print(f"\nTopic divs: {len(section_divs)}")
for d in section_divs[:5]:
    print(f"  {d[:100]}")

# Look for li elements with section in id
li_sections = re.findall(r'<li[^>]*id="[^"]*section[^"]*"[^>]*>', content, re.I)
print(f"\nLi sections: {len(li_sections)}")
for d in li_sections[:5]:
    print(f"  {d[:120]}")

# Find the actual course topics/sections text
print("\n--- Looking for section numbers/names ---")
section_texts = re.findall(r'(?:sectionname|topicsection)[^>]*>([^<]+)<', content, re.I)
for t in section_texts[:20]:
    print(f"  SECTION: {t.strip()}")

# Look for all links that might be class pages
all_links = re.findall(r'href="([^"]+)"[^>]*>([^<]{5,100})<', content)
print(f"\nAll meaningful links ({len(all_links)}):")
for href, text in all_links:
    if any(k in href.lower() for k in ["resource", "assignment", "quiz", "forum", "page", "lesson"]):
        print(f"  [{text.strip()[:50]}] -> {href[:80]}")
