import pandas as pd
import zipfile
import os
import xml.etree.ElementTree as ET

src = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"
ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

out_dir = r"D:\Temp\opencode\verify_final"
if os.path.exists(out_dir):
    import shutil
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

with zipfile.ZipFile(src, 'r') as z:
    z.extractall(out_dir)

def verify_sheet(sheet_num, sheet_name, expected_data):
    """Verify transferred values for first 2 students in a sheet"""
    sheet_path = os.path.join(out_dir, 'xl', 'worksheets', f'sheet{sheet_num}.xml')
    tree = ET.parse(sheet_path)
    root = tree.getroot()
    sheet_data = root.find(f'{{{ns}}}sheetData')

    print(f"\n{'='*50}")
    print(f"SHEET: {sheet_name}")
    print(f"{'='*50}")

    for excel_row in [11, 12]:
        for row in sheet_data.findall(f'{{{ns}}}row'):
            r = int(row.get('r'))
            if r == excel_row:
                cells = {}
                for cell in row.findall(f'{{{ns}}}c'):
                    ref = cell.get('r')
                    col = ''.join([c for c in ref if c.isalpha()])
                    v = cell.find(f'{{{ns}}}v')
                    if v is not None and v.text and col not in ['A','B']:
                        cells[col] = v.text

                print(f"  Row {r}:", end='')
                # Show key cells
                key_cols = ['C','D','E','F','G','H','I','J','K','L','S','T','AM','AN']
                for c in key_cols:
                    if c in cells:
                        print(f" {c}={cells[c]}", end='')
                print()
                break

# Verify each subject
verify_sheet(2, 'LENGUAJE', {})
verify_sheet(9, 'MATEMÁTICAS', {})
verify_sheet(6, 'SOCIALES', {})
verify_sheet(7, 'VALORES', {})
verify_sheet(10, 'TECNOLOGÍA', {})

# Also read with pandas to check overall
print("\n\n=== PANDAS VERIFICATION ===")
xl = pd.ExcelFile(src)
for sheet in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    df = pd.read_excel(src, sheet_name=sheet, header=None)
    print(f"\n{sheet} rows 11-12 (first 2 students):")
    print(df.iloc[10:12, :5].to_string())