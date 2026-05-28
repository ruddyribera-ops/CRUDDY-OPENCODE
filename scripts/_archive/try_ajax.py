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

# Try accessing with edit mode ON
# Also try different view parameters
course_id = 13443  # 5to Año

# Try various URLs
urls_to_try = [
    f"{BASE_URL}/course/view.php?id={course_id}",
    f"{BASE_URL}/course/view.php?id={course_id}&section=0",
    f"{BASE_URL}/course/view.php?id={course_id}&edit=1",
    f"{BASE_URL}/course/view.php?id={course_id}&sesskey=",  # add sesskey later
]

# First get the sesskey
resp = session.get(urls_to_try[0])
sesskey_match = re.search(r'sesskey:\s*["\']([^"\']+)["\']', resp.text)
sesskey = sesskey_match.group(1) if sesskey_match else ""
print(f"Sesskey: {sesskey}")

# Try with AJAX section loading
# In Moodle, sections are loaded via: /course/amd/inline.js or via service.php
ajax_url = f"{BASE_URL}/course/rest.php?courseid={course_id}&sesskey={sesskey}&info[0]=course&info[1]=coursecontent"
resp2 = session.get(ajax_url, headers={"X-Requested-With": "XMLHttpRequest"})
print(f"\nAJAX response status: {resp2.status_code}")
print(f"Response (first 1000 chars): {resp2.text[:1000]}")

# Try the course sections via WS
ws_url = f"{BASE_URL}/lib/ajax/service.php?sesskey={sesskey}&info=core_course_get_contents"
resp3 = session.post(ws_url, json=[{"index": 0, "methodname": "core_course_get_contents", "args": {"courseid": course_id, "options": []}}],
                     headers={"X-Requested-With": "XMLHttpRequest", "Content-Type": "application/json"})
print(f"\nWS response status: {resp3.status_code}")
print(f"WS Response: {resp3.text[:2000]}")
