import zipfile
import xml.etree.ElementTree as ET
import os

src = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"
ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

out_dir = r"D:\Temp\opencode\verify_headers2"
if os.path.exists(out_dir):
    import shutil
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

with zipfile.ZipFile(src, 'r') as z:
    z.extractall(out_dir)

# Check rows 6-9 for all subject sheets
for sheet_name, sheet_num in [('LENGUAJE', 2), ('MATEMÁTICAS', 9), ('SOCIALES', 6), ('VALORES', 7), ('TECNOLOGÍA', 10)]:
    sheet_path = os.path.join(out_dir, 'xl', 'worksheets', f'sheet{sheet_num}.xml')
    tree = ET.parse(sheet_path)
    root = tree.getroot()
    sheet_data = root.find(f'{{{ns}}}sheetData')

    # Get shared strings
    ss_path = os.path.join(out_dir, 'xl', 'sharedStrings.xml')
    ss_tree = ET.parse(ss_path)
    ss_root = ss_tree.getroot()
    strings = []
    for si in ss_root.findall(f'{{{ns}}}si'):
        t_elems = si.findall(f'.//{{{ns}}}t')
        text = ''.join(t.text or '' for t in t_elems)
        strings.append(text)

    print(f"\n{'='*50}")
    print(f"SHEET: {sheet_name}")
    print(f"{'='*50}")

    for row in sheet_data.findall(f'{{{ns}}}row'):
        r = int(row.get('r'))
        if 6 <= r <= 9:
            print(f"\nRow {r}:")
            for cell in row.findall(f'{{{ns}}}c'):
                ref = cell.get('r')
                t_attr = cell.get('t', 'number')
                v = cell.find(f'{{{ns}}}v')
                if t_attr == 's' and v is not None:
                    try:
                        print(f"  {ref}: STR[{v.text}] = '{strings[int(v.text)]}'")
                    except:
                        print(f"  {ref}: STR[{v.text}] = ERROR")
                elif v is not None:
                    print(f"  {ref}: {v.text}")