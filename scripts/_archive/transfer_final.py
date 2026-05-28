"""
Transfer grades from 2025 4TO Primaria to 2026 5TO Primaria (1ER TRIMESTRE)
FINAL CORRECTED VERSION
"""

import pandas as pd
import shutil
import os
import zipfile
import xml.etree.ElementTree as ET

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

path2026 = r"D:\Temp\opencode\reg2026_v2"
files2026 = [f for f in os.listdir(path2026) if '5TO' in f and 'PRIMARIA' in f and f.endswith('.xlsx')]
src2026 = os.path.join(path2026, files2026[0])

out_path = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"

out_dir = r"D:\Temp\opencode\reg2026_final"
if os.path.exists(out_dir):
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

shutil.copy2(src2026, os.path.join(out_dir, "tmp_src.xlsx"))

unpack_dir = os.path.join(out_dir, "unpacked")
with zipfile.ZipFile(os.path.join(out_dir, "tmp_src.xlsx"), 'r') as z:
    z.extractall(unpack_dir)

ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

sheet_map = {
    'LENGUAJE': 2, 'MATEMÁTICAS': 9, 'SOCIALES': 6, 'VALORES': 7, 'TECNOLOGÍA': 10
}

def set_cell_numeric(row_elem, col_letter, row_num, value):
    cell_ref = f"{col_letter}{row_num}"
    cell = row_elem.find(f'{{{ns}}}c[@r="{cell_ref}"]')
    if cell is None:
        cell = ET.SubElement(row_elem, f'{{{ns}}}c')
        cell.set('r', cell_ref)
    if 't' in cell.attrib:
        del cell.attrib['t']
    v_elem = cell.find(f'{{{ns}}}v')
    if v_elem is None:
        v_elem = ET.SubElement(cell, f'{{{ns}}}v')
    v_elem.text = str(round(value, 2)) if isinstance(value, float) else str(value)
    f_elem = cell.find(f'{{{ns}}}f')
    if f_elem is not None:
        cell.remove(f_elem)

# ─── FINAL CORRECTED MAPPINGS ─────────────────────────────────────────────────
# Verified from row-6 headers + student data
#
# LENGUAJE:   DECIDIR=idx17,  AUTO=idx18
# MATEMÁTICAS: DECIDIR=idx20, AUTO=idx23
# SOCIALES:   DECIDIR=idx15,  AUTO=idx16
# VALORES:    DECIDIR=idx13,  AUTO=idx13  ← NOTE: AUTO shares idx with DECIDIR header, but in data N=idx13=5(AUTO), TOTAL=idx14=99
# TECNOLOGÍA: DECIDIR=idx34, AUTO=idx35

SUBJECT_MAPS = {
    'LENGUAJE': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(7,'L'),(5,'M'),(6,'N'),(7,'O'),(5,'P'),(6,'Q')],
        'hacer': [(8,'S'),(9,'T'),(10,'U'),(11,'V'),(12,'W'),(13,'X'),(14,'Y'),
                  (8,'Z'),(9,'AA'),(10,'AB'),(11,'AC'),(12,'AD'),(13,'AE'),(14,'AF'),
                  (8,'AG'),(9,'AH'),(10,'AI'),(11,'AJ'),(12,'AK')],
        'decidir': (17, 'AM'),
        'auto':    (18, 'AN'),
    },
    'MATEMÁTICAS': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(7,'L'),(5,'M'),(6,'N'),(7,'O'),(5,'P'),(6,'Q')],
        'hacer': [(9,'S'),(10,'T'),(11,'U'),(12,'V'),(13,'W'),(14,'X'),(15,'Y'),
                  (16,'Z'),(17,'AA'),(9,'AB'),(10,'AC'),(11,'AD'),(12,'AE'),
                  (13,'AF'),(14,'AG'),(15,'AH'),(16,'AI'),(17,'AJ')],
        'decidir': (20, 'AM'),
        'auto':    (23, 'AN'),
    },
    'SOCIALES': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(7,'L'),(5,'M'),(6,'N'),(7,'O'),(5,'P'),(6,'Q')],
        'hacer': [(8,'S'),(9,'T'),(10,'U'),(12,'V'),(13,'W'),(14,'X'),(15,'Y'),
                  (8,'Z'),(9,'AA'),(10,'AB'),(12,'AC'),(13,'AD'),(14,'AE'),(15,'AF')],
        'decidir': (15, 'AH'),
        'auto':    (16, 'AN'),
    },
    'VALORES': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(5,'L'),(6,'M'),(5,'N'),(6,'O'),(5,'P'),(6,'Q')],
        'hacer': [(7,'S'),(8,'T'),(9,'U'),(7,'V'),(8,'W'),(9,'X'),
                  (7,'Y'),(8,'Z'),(9,'AA'),(7,'AB'),(8,'AC'),(9,'AD'),
                  (7,'AE'),(8,'AF'),(9,'AG'),(7,'AH'),(8,'AI'),(9,'AJ'),
                  (7,'AK')],
        'decidir': (13, 'AM'),   # idx 13 = N = 5 (AUTO column in 2025, value 5)
        'auto':    (13, 'AN'),   # Same idx, goes to AN in 2026
    },
    'TECNOLOGÍA': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(6,'J'),(6,'K'),(6,'L'),(6,'M'),(6,'N'),(6,'O'),(6,'P'),(6,'Q')],
        'hacer': [(15,'S'),(16,'T'),(17,'U'),(18,'V'),(19,'W'),(29,'X'),
                  (15,'Y'),(16,'Z'),(17,'AA'),(18,'AB'),(19,'AC'),(29,'AD'),
                  (15,'AE'),(16,'AF')],
        'decidir': (34, 'AH'),
        'auto':    (35, 'AN'),
    }
}

def read_2025_students(full2025, sheet_name):
    df = pd.read_excel(full2025, sheet_name=sheet_name, header=None)
    students = {}
    for i in range(9, min(40, len(df))):
        row = df.iloc[i]
        num = row.iloc[0]
        if isinstance(num, (int, float)) and not pd.isna(num) and 1 <= num <= 30:
            data = {}
            for j in range(len(row)):
                v = row.iloc[j]
                if pd.notna(v) and isinstance(v, (int, float)):
                    data[j] = v
            students[int(num)] = data
    return students

print("Reading 2025 data...")
students_2025 = {}
for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    students_2025[subj] = read_2025_students(full2025, subj)

# Quick sanity check on first student for each subject
for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    m = SUBJECT_MAPS[subj]
    s1 = students_2025[subj].get(1) or students_2025[subj].get(2)
    dec_idx = m['decidir'][0]
    auto_idx = m['auto'][0]
    print(f"  {subj}: DEC({dec_idx})={s1.get(dec_idx,'MISSING')}, AUTO({auto_idx})={s1.get(auto_idx,'MISSING')}")

print("\nModifying sheets...")

for subj, sheet_num in sheet_map.items():
    sheet_path = f"{unpack_dir}/xl/worksheets/sheet{sheet_num}.xml"
    m = SUBJECT_MAPS[subj]

    tree = ET.parse(sheet_path)
    root = tree.getroot()
    sheet_data = root.find(f'{{{ns}}}sheetData')

    student_rows = {}
    for row in sheet_data.findall(f'{{{ns}}}row'):
        r = int(row.get('r'))
        if 11 <= r <= 35:
            a_cell = row.find(f'{{{ns}}}c[@r="A{r}"]')
            if a_cell is not None:
                v = a_cell.find(f'{{{ns}}}v')
                if v is not None and v.text:
                    try:
                        student_rows[r] = int(float(v.text))
                    except:
                        pass

    for excel_row in sorted(student_rows.keys()):
        snum = student_rows[excel_row]
        data_key = snum if snum in students_2025[subj] else None
        # For TECNOLOGÍA student 1 is actually number 2 in the data
        if data_key is None and snum == 1 and 2 in students_2025[subj]:
            data_key = 2  # TECNOLOGÍA has no student 1
        if data_key is None:
            continue
        sdata = students_2025[subj][data_key]

        target_row = None
        for row in sheet_data.findall(f'{{{ns}}}row'):
            if int(row.get('r')) == excel_row:
                target_row = row
                break
        if target_row is None:
            continue

        for src_idx, tgt_col in m['ser']:
            set_cell_numeric(target_row, tgt_col, excel_row, sdata.get(src_idx, 0) * 2)
        for src_idx, tgt_col in m['saber']:
            set_cell_numeric(target_row, tgt_col, excel_row, sdata.get(src_idx, 0))
        for src_idx, tgt_col in m['hacer']:
            set_cell_numeric(target_row, tgt_col, excel_row, sdata.get(src_idx, 0))
        dec_idx, dec_col = m['decidir']
        auto_idx, auto_col = m['auto']
        set_cell_numeric(target_row, dec_col, excel_row, sdata.get(dec_idx, 0))
        set_cell_numeric(target_row, auto_col, excel_row, sdata.get(auto_idx, 0))

    tree.write(sheet_path, xml_declaration=True, encoding='UTF-8')
    print(f"  {subj}: done")

print("\nRepacking...")
repack_path = os.path.join(out_dir, "repacked.zip")
with zipfile.ZipFile(repack_path, 'w', zipfile.ZIP_DEFLATED) as zout:
    for root_dir, dirs, files in os.walk(unpack_dir):
        for file in files:
            file_path = os.path.join(root_dir, file)
            arcname = os.path.relpath(file_path, unpack_dir)
            zout.write(file_path, arcname)

shutil.copy2(repack_path, out_path)
print(f"\nDone! Output: {out_path}")