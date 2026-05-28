import requests
from bs4 import BeautifulSoup
import re
import sys
import json
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

# Get the sesskey from M.cfg
main_page = session.get(f"{BASE_URL}/my/")
sesskey_match = re.search(r'sesskey["\']:\s*["\']([^"\']+)["\']', main_page.text)
sesskey = sesskey_match.group(1) if sesskey_match else ""
print(f"Sesskey from my/: {sesskey}")

# Now try to get course contents via WS
# Try core_course_get_contents
ws_payload = [{
    "index": 0,
    "methodname": "core_course_get_contents",
    "args": {
        "courseid": 13443,
        "options": [{"name": "includecustomfields", "value": "1"}]
    }
}]

ws_url = f"{BASE_URL}/lib/ajax/service.php?sesskey={sesskey}"
headers = {"X-Requested-With": "XMLHttpRequest", "Content-Type": "application/json"}
resp_ws = session.post(ws_url, json=ws_payload, headers=headers)
print(f"\nWS Status: {resp_ws.status_code}")
print(f"WS Response: {resp_ws.text[:3000]}")

# Also try to access with includestudents=1 and other options
# Try getting course nav via gradebook
grade_url = f"{BASE_URL}/grade/report/overview/index.php?id=13443"
resp_grade = session.get(grade_url)
print(f"\nGradebook status: {resp_grade.status_code}")
print(f"Gradebook URL: {resp_grade.url}")

# Try the course category page to see all courses
cat_url = f"{BASE_URL}/course/index.php?categoryid=0"
resp_cat = session.get(cat_url)
soup_cat = BeautifulSoup(resp_cat.text, "html.parser")

# Find 5to courses in the category
print("\n=== Courses in category ===")
for a in soup_cat.find_all("a", href=re.compile(r"course/view\.php\?id=\d+")):
    text = a.text.strip()
    if text and ("5" in text or "secundaria" in text.lower() or "año" in text.lower()):
        print(f"  {text[:60]} | {a['href']}")
