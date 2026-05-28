import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("course_13443.html", "r", encoding="utf-8") as f:
    content = f.read()

# Find ALL section li elements
all_sections = re.findall(r'<li[^>]*id="section-(\d+)"[^>]*>(.*?)</li>', content, re.DOTALL | re.I)
print(f"Found {len(all_sections)} sections")

for sec_num, sec_html in all_sections:
    print(f"\n=== SECTION {sec_num} ===")
    # Extract section name
    name_match = re.search(r'sectionname[^>]*>([^<]+)<', sec_html, re.I)
    name = name_match.group(1).strip() if name_match else "(no name)"
    print(f"Name: {name}")
    
    # Extract all activity links
    activities = re.findall(r'<a[^>]*href="([^"]+)"[^>]*>([^<]{3,100})<', sec_html)
    for href, text in activities:
        text = text.strip()
        if text and href:
            print(f"  [{text}] -> {href[:80]}")
    
    # Also look for section content items
    content_items = re.findall(r'course-content-item[^>]*>(.*?)</div>', sec_html, re.DOTALL)
    for item in content_items[:5]:
        text = re.sub(r'<[^>]+>', ' ', item).strip()
        if text:
            print(f"  Content: {text[:100]}")

# Let's also look for any JSON data in the page
json_data = re.findall(r'require\([\'"]([^\'"]+)[\'"]', content)
print(f"\n=== RequireJS modules ({len(json_data)}) ===")
for m in json_data[:20]:
    print(f"  {m}")

# Check for the actual course format - maybe it's tiles or collapsed
print("\n=== Checking course format ===")
for fmt in ["tiles", "topics", "weeks", "collapsed", "grid", "single"]:
    if fmt in content.lower():
        print(f"  Found: {fmt}")

# Let's try looking at the course content via the direct section URL
# In Moodle: course/view.php?id=XX&section=Y
print("\n=== Trying to find section URLs ===")
section_urls = re.findall(r'href="([^"]*section=\d+[^"]*)"', content)
for u in section_urls[:10]:
    print(f"  {u[:100]}")

# Find all AJAX endpoints
ajax_urls = re.findall(r'url\s*:\s*["\']([^"\']+)["\']', content)
print(f"\n=== AJAX URLs ({len(ajax_urls)}) ===")
for u in ajax_urls[:15]:
    print(f"  {u[:100]}")

# Find the course content collapse div
collapse = re.search(r'id="coursecontentcollapse(\d+)"', content)
if collapse:
    print(f"\n=== Course content collapse ID: {collapse.group(1)} ===")
    # Find the content after this
    start = collapse.end()
    next_500 = content[start:start+500]
    print(next_500[:500])
