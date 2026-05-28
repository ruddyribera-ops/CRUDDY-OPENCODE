import requests
from bs4 import BeautifulSoup
import re
import sys
import json
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "https://academia.creativos-digitales.com"
session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0"})

# Re-login
resp = session.get(f"{BASE_URL}/login/index.php")
soup = BeautifulSoup(resp.text, "html.parser")
token = soup.find("input", {"name": "logintoken"})["value"]
session.post(f"{BASE_URL}/login/index.php", data={
    "username": "misterruddy@laspalmas.edu.bo",
    "password": "Capacitaciones2025",
    "logintoken": token
}, allow_redirects=True)

def scrape_course(course_id, course_name):
    print(f"\n{'='*60}")
    print(f"SCRAPING: {course_name} (id={course_id})")
    print('='*60)
    
    url = f"{BASE_URL}/course/view.php?id={course_id}"
    resp = session.get(url)
    soup = BeautifulSoup(resp.text, "html.parser")
    
    # Save full page for debugging
    with open(f"course_{course_id}.html", "w", encoding="utf-8") as f:
        f.write(resp.text)
    
    # Find all sections (weeks/topics)
    # Moodle uses .topic, .week, or .sections
    sections = soup.find_all("li", {"id": re.compile(r"section-|topic-")})
    if not sections:
        sections = soup.find_all("div", {"class": re.compile(r"topic|section|week")})
    
    print(f"Found {len(sections)} sections")
    
    content = {}
    
    # Try to find section names
    for section in sections:
        # Section title might be in .sectionname, .topic_title, or h3
        section_title = ""
        title_el = section.find(class_=re.compile(r"sectionname|title"))
        if title_el:
            section_title = title_el.text.strip()
        
        # Find all activities/resources in this section
        activities = []
        for a in section.find_all("a", {"class": re.compile(r"aalink|activityicon")}):
            act_name = a.text.strip()
            act_href = a.get("href", "")
            if act_name and act_href:
                activities.append({"name": act_name, "href": act_href})
        
        if section_title or activities:
            content[section_title] = activities
    
    # Also try: look for .mod-indent-outer, .activity
    activities_all = soup.find_all("div", {"class": re.compile(r"activity|mod-indent")})
    print(f"Found {len(activities_all)} activity divs")
    
    # Print structure
    for section in sections[:20]:
        title_el = section.find(class_=re.compile(r"sectionname"))
        title = title_el.text.strip() if title_el else "(sin titulo)"
        
        # Get all activity links
        aalink_acts = section.find_all("a", {"class": re.compile(r"aalink")})
        if aalink_acts:
            acts = aalink_acts
        else:
            acts = section.find_all("a", {"href": re.compile(r"mod|resource|assignment")})
        activity_names = [a.text.strip() for a in acts if a.text.strip()]
        
        if activity_names:
            print(f"\n[ {title} ]")
            for act in activity_names:
                print(f"  - {act}")
        else:
            # Maybe it has no activities, just content
            text_content = section.get_text(separator=" | ", strip=True)[:150]
            if text_content and len(text_content) > 10:
                print(f"\n[ {title} ]")
                print(f"  Content: {text_content[:100]}")
    
    return content

# Scrape 5to Secundaria (id=13443) and 4to (id=13442)
scrape_course(13443, "5to Ano Las Palmas School")
scrape_course(13442, "4to Ano Las Palmas School")
