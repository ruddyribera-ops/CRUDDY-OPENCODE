import requests
from bs4 import BeautifulSoup
import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "https://academia.creativos-digitales.com"
session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0"})

# Login
resp = session.get(f"{BASE_URL}/login/index.php")
soup = BeautifulSoup(resp.text, "html.parser")
token = soup.find("input", {"name": "logintoken"})["value"]
session.post(f"{BASE_URL}/login/index.php", data={
    "username": "misterruddy@laspalmas.edu.bo",
    "password": "Capacitaciones2025",
    "logintoken": token
}, allow_redirects=True)

def get_course_sections(course_id, course_name):
    url = f"{BASE_URL}/course/view.php?id={course_id}"
    resp = session.get(url)
    soup = BeautifulSoup(resp.text, "html.parser")
    
    print(f"\n{'='*60}")
    print(f"COURSE: {course_name} ({course_id})")
    print('='*60)
    
    # Find ALL section li elements
    sections = soup.find_all("li", {"id": re.compile(r"section-\d+")})
    print(f"Sections found: {len(sections)}")
    
    for sec in sections:
        sec_id = sec.get("id", "")
        # Section title
        title_el = sec.find("h3", {"class": re.compile(r"sectionname")})
        title = title_el.text.strip() if title_el else sec_id
        print(f"\n--- Section: {title} ---")
        
        # Find all activity items within this section
        activities = sec.find_all("li", {"class": re.compile(r"activity-wrapper")})
        for act in activities:
            act_name_el = act.find("span", {"class": "instancename"})
            act_name = act_name_el.text.strip() if act_name_el else "?"
            act_type = act.get("class", [])
            # Get mod type
            mod_type = [c for c in act.get("class", []) if c.startswith("modtype_")]
            mod_type = mod_type[0].replace("modtype_", "") if mod_type else "?"
            
            href = ""
            a_tag = act.find("a", href=True)
            if a_tag:
                href = a_tag["href"]
            
            print(f"  [{mod_type}] {act_name[:60]} | {href[:60]}")

# Try all 5to-related courses
for course_id, course_name in [
    (13443, "5º Año Las Palmas School"),
    (13454, "5º Año Robótica Las Palmas School"),
    (13442, "4º Año Las Palmas School"),
    (13453, "4º Año Robótica Las Palmas School"),
    (13444, "1º Grado Robótica Las Palmas School"),  # youngest primary
    (13433, "1º Grado Las Palmas School"),  # youngest primary regular
]:
    try:
        get_course_sections(course_id, course_name)
    except Exception as e:
        print(f"Error with {course_id}: {e}")
