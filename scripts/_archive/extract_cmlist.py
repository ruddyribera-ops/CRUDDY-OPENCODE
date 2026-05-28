import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

with open("course_13443.html", "r", encoding="utf-8") as f:
    content = f.read()

# Find the cmlist ul which contains the actual content
cmlist_match = re.search(r'<ul[^>]*data-for="cmlist"[^>]*>(.*?)</ul>', content, re.DOTALL | re.I)
if cmlist_match:
    cmlist_html = cmlist_match.group(1)
    print("CMlist content:")
    print(cmlist_html[:5000])
    
    # Find all activity items
    print("\n\n=== All activities in cmlist ===")
    # Each activity is in a li with class containing 'activity'
    activity_items = re.findall(r'<li[^>]*class="[^"]*activity[^"]*"[^>]*>(.*?)</li>', cmlist_html, re.DOTALL | re.I)
    print(f"Found {len(activity_items)} activity items")
    
    for i, item in enumerate(activity_items):
        # Get activity name
        name_match = re.search(r'instance="\d+"[^>]*>([^<]+)<', item)
        if not name_match:
            name_match = re.search(r'activityname[^>]*>([^<]+)<', item, re.I)
        if not name_match:
            name_match = re.search(r'<span[^>]*>([^<]{3,100})</span>', item)
        
        # Get href
        href_match = re.search(r'href="([^"]+)"', item)
        
        name = name_match.group(1).strip() if name_match else "(no name)"
        href = href_match.group(1) if href_match else "(no href)"
        print(f"  {i+1}. [{name}] -> {href[:80]}")
        
else:
    print("cmlist not found!")
    
    # Maybe the course content is loaded via JavaScript - let's look for the content anyway
    # by searching for activity li elements in entire content
    all_activity_lis = re.findall(r'<li[^>]*class="[^"]*activity[^"]*"', content, re.I)
    print(f"All activity lis in document: {len(all_activity_lis)}")
    for li in all_activity_lis[:5]:
        print(f"  {li[:100]}")
