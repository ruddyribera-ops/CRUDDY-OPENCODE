import zipfile
import xml.etree.ElementTree as ET
import os

src = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"
ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

out_dir = r"D:\Temp\opencode\verify_headers"
sheet_path = os.path.join(out_dir, 'xl', 'worksheets', 'sheet2.xml')  # LENGUAJE
tree = ET.parse(sheet_path)
root = tree.getroot()
sheet_data = root.find(f'{{{ns}}}sheetData')

# Get shared strings
ss_path = os.path.join(out_dir, 'xl', 'sharedStrings.xml')
ss_tree = ET.parse(ss_path)
ss_root = ss_tree.getroot()

strings = []
for i, si in enumerate(ss_root.findall(f'{{{ns}}}si')):
    t_elems = si.findall(f'.//{{{ns}}}t')
    text = ''.join(t.text or '' for t in t_elems)
    strings.append(text)

def get_str(idx):
    try:
        return strings[int(idx)]
    except:
        return f"[bad idx {idx}]"

# Show rows 5-9 in detail
for row in sheet_data.findall(f'{{{ns}}}row'):
    r = int(row.get('r'))
    if 5 <= r <= 9:
        print(f"\n--- Row {r} ---")
        for cell in row.findall(f'{{{ns}}}c'):
            ref = cell.get('r')
            t_attr = cell.get('t', 'number')
            v = cell.find(f'{{{ns}}}v')
            f_elem = cell.find(f'{{{ns}}}f')
            if t_attr == 's' and v is not None:
                print(f"  {ref}: STR[{v.text}] = '{get_str(v.text)}'")
            elif v is not None:
                print(f"  {ref}: {v.text}" + (f" FORMULA={f_elem.text}" if f_elem is not None else ""))