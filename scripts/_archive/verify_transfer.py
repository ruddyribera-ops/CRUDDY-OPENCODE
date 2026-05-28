import pandas as pd
import zipfile
import os
import xml.etree.ElementTree as ET

src = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"

# Read with pandas to verify
xl = pd.ExcelFile(src)
print("Sheets:", xl.sheet_names)

ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

# Unpack and check XML
out_dir = r"D:\Temp\opencode\verify_out"
if os.path.exists(out_dir):
    import shutil
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

with zipfile.ZipFile(src, 'r') as z:
    z.extractall(out_dir)

# Check LENGUAJE sheet (sheet2), row 11 (first student)
sheet2 = os.path.join(out_dir, 'xl', 'worksheets', 'sheet2.xml')
tree = ET.parse(sheet2)
root = tree.getroot()
sheet_data = root.find(f'{{{ns}}}sheetData')

print("\nLENGUAJE row 11 (student 1 ARACENA):")
for row in sheet_data.findall(f'{{{ns}}}row'):
    r = int(row.get('r'))
    if r == 11:
        for cell in row.findall(f'{{{ns}}}c'):
            ref = cell.get('r')
            col = ''.join([c for c in ref if c.isalpha()])
            if col in ['C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','AM','AN']:
                v = cell.find(f'{{{ns}}}v')
                f = cell.find(f'{{{ns}}}f')
                if v is not None and v.text:
                    print(f"  {ref}: {v.text}" + (f" (formula: {f.text})" if f is not None else ""))

# Check SOCIALES sheet (sheet6), row 11
sheet6 = os.path.join(out_dir, 'xl', 'worksheets', 'sheet6.xml')
tree = ET.parse(sheet6)
root = tree.getroot()
sheet_data = root.find(f'{{{ns}}}sheetData')

print("\nSOCIALES row 11 (student 1 ARACENA):")
for row in sheet_data.findall(f'{{{ns}}}row'):
    r = int(row.get('r'))
    if r == 11:
        for cell in row.findall(f'{{{ns}}}c'):
            ref = cell.get('r')
            col = ''.join([c for c in ref if c.isalpha()])
            if col in ['C','D','E','F','G','H','I','J','K','L','S','T','U','V','W','X','Y','Z','AA','AB','AH','AN']:
                v = cell.find(f'{{{ns}}}v')
                f = cell.find(f'{{{ns}}}f')
                if v is not None and v.text:
                    print(f"  {ref}: {v.text}" + (f" (formula: {f.text})" if f is not None else ""))