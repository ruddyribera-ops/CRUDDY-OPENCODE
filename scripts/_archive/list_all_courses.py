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

# Get ALL courses from the category page
cat_url = f"{BASE_URL}/course/index.php?categoryid=0"
resp_cat = session.get(cat_url)
soup_cat = BeautifulSoup(resp_cat.text, "html.parser")

print("=== ALL courses on platform ===")
all_course_links = {}
for a in soup_cat.find_all("a", href=re.compile(r"course/view\.php\?id=\d+")):
    text = a.text.strip()
    href = a["href"]
    if text and href not in all_course_links:
        all_course_links[href] = text

for href, text in sorted(all_course_links.items(), key=lambda x: x[1]):
    print(f"  {text[:60]:<65} | {href}")

print(f"\nTotal unique courses: {len(all_course_links)}")

# Also check the course index page by searching for category pages
print("\n=== Trying to find 6to Año ===")
for a in soup_cat.find_all("a", href=True):
    text = a.text.strip().lower()
    if "6" in text and ("año" in text or "secundaria" in text):
        print(f"  {a.text.strip()[:60]} | {a['href']}")
