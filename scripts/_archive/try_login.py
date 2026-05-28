import requests
from bs4 import BeautifulSoup
import sys
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "https://academia.creativos-digitales.com"

# Try different username formats
credentials_to_try = [
    ("MISTERRUDY@LASPALMAS.EDU.BO", "Capacitaciones2025"),
    ("MISTERRUDY", "Capacitaciones2025"),
    ("misterudy@laspalmas.edu.bo", "Capacitaciones2025"),
    ("Mister Rudy", "Capacitaciones2025"),
    ("MISTERRUDY@LASPALMAS.EDU.BO", "capaciones2025"),  # typo check
    ("MISTERRUDY@LASPALMAS.EDU.BO", "Capacitaciones 2025"),  # with space
]

session = requests.Session()
session.headers.update({"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0"})

for username, password in credentials_to_try:
    print(f"\n=== Trying: {username} | {password} ===")
    s = requests.Session()
    s.headers.update({"User-Agent": "Mozilla/5.0"})
    
    # Get fresh login page
    resp = s.get(f"{BASE_URL}/login/index.php")
    soup = BeautifulSoup(resp.text, "html.parser")
    token = soup.find("input", {"name": "logintoken"})
    token_value = token["value"] if token else ""
    
    login_data = {"username": username, "password": password}
    if token_value:
        login_data["logintoken"] = token_value
    
    resp2 = s.post(f"{BASE_URL}/login/index.php", data=login_data, allow_redirects=True)
    
    if "login" in resp2.url.lower():
        # Check error
        error_soup = BeautifulSoup(resp2.text, "html.parser")
        error_div = error_soup.find("div", {"class": lambda x: x and "alert" in x and "danger" in x})
        if error_div:
            print(f"  ERROR: {error_div.text.strip()}")
        else:
            print(f"  Still on login page, no error div found")
    else:
        print(f"  SUCCESS! Landed on: {resp2.url}")
        # Show dashboard title
        dash_soup = BeautifulSoup(resp2.text, "html.parser")
        title = dash_soup.find("title")
        print(f"  Page title: {title.text if title else 'N/A'}")
        # Save it
        with open("dashboard_success.html", "w", encoding="utf-8") as f:
            f.write(resp2.text)
        print(f"  Saved to dashboard_success.html")
        break
