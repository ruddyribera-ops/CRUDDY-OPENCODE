import zipfile
import os

path2026 = r"D:\Temp\opencode\reg2026_v2"
files2026 = [f for f in os.listdir(path2026) if '5TO' in f and 'PRIMARIA' in f and f.endswith('.xlsx')]
src = os.path.join(path2026, files2026[0])

# Unpack to examine XML
import shutil
unpack_dir = r"D:\Temp\opencode\reg2026_unpack"
if os.path.exists(unpack_dir):
    shutil.rmtree(unpack_dir)
os.makedirs(unpack_dir)

with zipfile.ZipFile(src, 'r') as z:
    z.extractall(unpack_dir)

# List worksheets
sheet_dir = os.path.join(unpack_dir, 'xl', 'worksheets')
sheets = os.listdir(sheet_dir)
print("Sheet files:", sheets)

# Read workbook to get sheet names
import xml.etree.ElementTree as ET
wb = ET.parse(os.path.join(unpack_dir, 'xl', 'workbook.xml'))
ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
sheet_names = [(s.get('sheetId'), s.get('name')) for s in wb.findall('.//ns:sheet', ns)]
print("Sheet IDs and names:", sheet_names)

# Read the LENGUAJE sheet (sheet2 based on order)
# First let's see which sheet number LENGUAJE is
for i, name in sheet_names:
    if 'LENGUAJE' in name.upper() or 'MATEM' in name.upper():
        print(f"\nFound: {name} (ID={i})")
        # Find the actual file
        rels = ET.parse(os.path.join(unpack_dir, 'xl', '_rels', 'workbook.xml.rels'))
        for rel in rels.findall('.//{http://schemas.openxmlformats.org/package/2006/relationships}Relationship'):
            if rel.get('Id') == f'rId{i}':
                target = rel.get('Target')
                print(f"  File: {target}")
                break