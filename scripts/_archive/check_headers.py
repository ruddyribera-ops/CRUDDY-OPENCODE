import zipfile
import xml.etree.ElementTree as ET
import os

src = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"
ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

out_dir = r"D:\Temp\opencode\verify_headers"
if os.path.exists(out_dir):
    import shutil
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

with zipfile.ZipFile(src, 'r') as z:
    z.extractall(out_dir)

# LENGUAJE = sheet2
# MATEMATICAS = sheet9
# SOCIALES = sheet6
# VALORES = sheet7
# TECNOLOGÍA = sheet10

for sheet_name, sheet_num in [('LENGUAJE', 2), ('MATEMÁTICAS', 9), ('SOCIALES', 6), ('VALORES', 7), ('TECNOLOGÍA', 10)]:
    sheet_path = os.path.join(out_dir, 'xl', 'worksheets', f'sheet{sheet_num}.xml')
    tree = ET.parse(sheet_path)
    root = tree.getroot()
    sheet_data = root.find(f'{{{ns}}}sheetData')

    print(f"\n{'='*60}")
    print(f"SHEET: {sheet_name}")
    print(f"{'='*60}")

    # Show rows 5, 6, 7
    for row in sheet_data.findall(f'{{{ns}}}row'):
        r = int(row.get('r'))
        if r in [5, 6, 7]:
            print(f"\nRow {r}:")
            for cell in row.findall(f'{{{ns}}}c'):
                ref = cell.get('r')
                v = cell.find(f'{{{ns}}}v')
                t = cell.get('t', 'number')
                if v is not None and v.text:
                    # Get shared string if type is 's'
                    if t == 's':
                        # Get from sharedStrings
                        print(f"  {ref}: [str idx={v.text}]")
                    else:
                        print(f"  {ref}: {v.text}")

# Also get shared strings
ss_path = os.path.join(out_dir, 'xl', 'sharedStrings.xml')
ss_tree = ET.parse(ss_path)
ss_root = ss_tree.getroot()

print("\n\n=== SHARED STRINGS (relevant) ===")
for i, si in enumerate(ss_root.findall(f'{{{ns}}}si')):
    t_elems = si.findall(f'.//{{{ns}}}t')
    text = ''.join(t.text or '' for t in t_elems)
    if text.strip() and any(k in text.upper() for k in ['CRITERIO', 'INSTRUMENTO', 'EVALUA', 'SABER', 'HACER', 'DECIDIR', 'SER', 'PROMEDIO', 'AULA', 'RESPETO']):
        print(f"  [{i}]: {text[:100]}")