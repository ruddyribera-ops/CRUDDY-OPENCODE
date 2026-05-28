import xml.etree.ElementTree as ET

def get_sheet_path(unpack_dir, sheet_name_map, target_name):
    """Get sheet XML path from sheet name"""
    # sheet_name_map: {name: sheetNum}
    sheet_num = sheet_name_map.get(target_name)
    if not sheet_num:
        return None
    return f"{unpack_dir}/xl/worksheets/sheet{sheet_num}.xml"

unpack_dir = r"D:\Temp\opencode\reg2026_unpack"

# Sheet mappings from workbook.xml.rels
sheet_map = {
    'ASISTENCIAS': 1,
    'LENGUAJE': 2,
    'MÚSICA': 3,
    'INGLES': 4,
    'PORTUGUÉS': 5,
    'SOCIALES': 6,
    'VALORES': 7,
    'ARTES': 8,
    'MATEMÁTICAS': 9,
    'TECNOLOGÍA': 10,
    'ED. FÍSICA': 11,
    'CIENCIAS NATURALES': 12,
    'PROMEDIO LENGUAS': 13,
    '1er Trim': 14,
    'Cuadro de honor': 15,
    'BOLENTINES 2026': 16
}

ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

subjects = ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']

for subj in subjects:
    path = f"{unpack_dir}/xl/worksheets/sheet{sheet_map[subj]}.xml"
    tree = ET.parse(path)
    root = tree.getroot()
    sheet_data = root.find(f'{{{ns}}}sheetData')

    print(f"\n{'='*60}")
    print(f"SUBJECT: {subj}")
    print(f"{'='*60}")

    # Find the student data rows (look for rows with student number in first col)
    for row in sheet_data.findall(f'{{{ns}}}row'):
        r = row.get('r')
        cells = {}
        formulas = {}
        for cell in row.findall(f'{{{ns}}}c'):
            ref = cell.get('r')
            col = ''.join([c for c in ref if c.isalpha()])
            f_elem = cell.find(f'{{{ns}}}f')
            v_elem = cell.find(f'{{{ns}}}v')
            t = cell.get('t', 'number')

            if f_elem is not None:
                formulas[ref] = f_elem.text
            elif v_elem is not None and t != 's':
                try:
                    cells[col] = float(v_elem.text)
                except:
                    pass

        if formulas:
            # Show row number and which cells have formulas
            formula_cols = {''.join([c for c in k if c.isalpha()]): v for k, v in formulas.items()}
            print(f"  Row {r} formulas: {formula_cols}")
            # Also show first cell value (student number check)
            first_val = cells.get('A', cells.get('B', None))
            print(f"  Row {r} A={cells.get('A')}, B type={formulas.get('B', 'no formula')}")
            if r == '11':  # Just show row 11 in detail
                print(f"    ALL formulas: {formulas}")
        elif r.isdigit() and int(r) >= 11 and int(r) <= 13:
            print(f"  Row {r}: A={cells.get('A')}, B={cells.get('B')}")