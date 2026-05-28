import requests
from bs4 import BeautifulSoup
import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

USERNAME = "misterruddy@laspalmas.edu.bo"
PASSWORD = "Capacitaciones2025"
BASE_URL = "https://academia.creativos-digitales.com"

session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0"})

# 1. Get login page
print("=== Getting login page ===")
resp = session.get(f"{BASE_URL}/login/index.php")
soup = BeautifulSoup(resp.text, "html.parser")

token = soup.find("input", {"name": "logintoken"})
token_value = token["value"] if token else ""
print(f"Token: {token_value[:20]}...")

# 2. POST login
print("=== Logging in ===")
login_data = {"username": USERNAME, "password": PASSWORD, "logintoken": token_value}
resp2 = session.post(f"{BASE_URL}/login/index.php", data=login_data, allow_redirects=True)
print(f"Status: {resp2.status_code}")
print(f"Final URL: {resp2.url}")

if "login" in resp2.url.lower():
    print("FAILED - still on login page")
    error_soup = BeautifulSoup(resp2.text, "html.parser")
    error_div = error_soup.find("div", {"class": lambda x: x and "alert" in x and "danger" in x})
    if error_div:
        print(f"ERROR: {error_div.text.strip()}")
    with open("login_fail.html", "w", encoding="utf-8") as f:
        f.write(resp2.text)
else:
    print("LOGIN SUCCESS!")
    dash_soup = BeautifulSoup(resp2.text, "html.parser")
    title = dash_soup.find("title")
    print(f"Page title: {title.text if title else 'N/A'}")
    
    # Save dashboard
    with open("dashboard.html", "w", encoding="utf-8") as f:
        f.write(resp2.text)
    print("Saved dashboard.html")

    # Find ALL course links
    print("\n=== All course links ===")
    for a in dash_soup.find_all("a", href=re.compile(r"course/view\.php")):
        name = a.text.strip()
        href = a["href"]
        if name:
            print(f"  {name[:70]} | {href}")

    # Find sidebar or navigation links to courses
    print("\n=== Sidebar/nav course links ===")
    for a in dash_soup.find_all("a", href=True):
        href = a["href"]
        text = a.text.strip()
        if text and ("secundaria" in text.lower() or "primaria" in text.lower()):
            print(f"  {text[:60]} | {href}")
