import xml.etree.ElementTree as ET

# Parse the 2026 LENGUAJE sheet
tree = ET.parse(r"D:\Temp\opencode\reg2026_unpack\xl\worksheets\sheet2.xml")
root = tree.getroot()
ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

# Get all rows
sheet_data = root.find(f'{{{ns}}}sheetData')
for row in sheet_data.findall(f'{{{ns}}}row'):
    r = row.get('r')
    if r in ['10', '11', '12']:
        print(f"\n--- Row {r} ---")
        for cell in row.findall(f'{{{ns}}}c'):
            ref = cell.get('r')
            f_elem = cell.find(f'{{{ns}}}f')
            v_elem = cell.find(f'{{{ns}}}v')
            t = cell.get('t', 'number')
            if f_elem is not None:
                print(f"  {ref}: formula={f_elem.text}, v={v_elem.text if v_elem is not None else 'None'}, t={t}")
            elif v_elem is not None:
                print(f"  {ref}: value={v_elem.text}, t={t}")
            else:
                print(f"  {ref}: EMPTY, t={t}")

# Also look at header rows to understand the column mapping
print("\n\n--- Row 6 (CRITERIOS DE EVALUACIÓN) ---")
for row in sheet_data.findall(f'{{{ns}}}row'):
    r = row.get('r')
    if r == '6':
        for cell in row.findall(f'{{{ns}}}c'):
            ref = cell.get('r')
            v_elem = cell.find(f'{{{ns}}}v')
            t = cell.get('t', 'number')
            if v_elem is not None:
                print(f"  {ref}: v={v_elem.text}, t={t}")