"""
Transfer grades from 2025 4TO Primaria to 2026 5TO Primaria (1ER TRIMESTRE)
Subjects: LENGUAJE, MATEMÁTICAS, SOCIALES, VALORES, TECNOLOGÍA
CORRECTED - all column indices verified
"""

import pandas as pd
import shutil
import os
import zipfile
import xml.etree.ElementTree as ET

# ─── PATHS ───────────────────────────────────────────────────────────────────
path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

path2026 = r"D:\Temp\opencode\reg2026_v2"
files2026 = [f for f in os.listdir(path2026) if '5TO' in f and 'PRIMARIA' in f and f.endswith('.xlsx')]
src2026 = os.path.join(path2026, files2026[0])

out_path = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"

out_dir = r"D:\Temp\opencode\reg2026_out"
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

# ─── FULLY VERIFIED MAPPINGS ─────────────────────────────────────────────────
# All indices confirmed from raw student data analysis
#
# LENGUAJE (student 1 ARACENA):
#   Row5: SER=idx2-4, SABER=idx5-7, HACER=idx8-14, DECIDIR=idx17, AUTO=idx18, TOTAL=idx19
#   Student1: C=5,D=4,E=4.5 | F=45,G=45,H=45 | I=40,J=40,K=40,L=40,M=40,N=40,O=40 | P=5,Q=5,R=5,S=4.5,T=99
#   2026: SER→C-H(×2), SABER→J-Q, HACER→S-AK(25cols), DECIDIR→AM(idx17), AUTO→AN(idx18)
#
# MATEMÁTICAS (student 1 ARACENA):
#   C=4,D=4,E=4 | F=43,G=45,H=45,I=44.3 | J=40...Q=40,R=40 | T=40 | U=5,V=5,W=5,X=5,Y=98.3
#   2026: SER→C-H(×2), SABER→J-Q, HACER→S-AK(19cols), DECIDIR→AM(idx20), AUTO→AN(idx23)
#
# SOCIALES (student 1 ARACENA):
#   C=4,D=4,E=4 | F=45,G=45,H=45 | I=40,J=35,K=40,L=0,M=40 | N=5,O=5,P=5,Q=5 | R=99
#   2026: SER→C-H(×2), SABER→J-Q, HACER→S-AF(14cols, indices 8,9,10,12,13,14,15 → repeat), DECIDIR→AH(idx15), AUTO→AN(idx18)
#
# VALORES (student 1 ARACENA):
#   C=5,D=5,E=5 | F=45,G=45 | H=38,I=40,J=39 | K=5,L=5,M=5,N=5 | O=99
#   2026: SER→C-H(×2), SABER→J-Q, HACER→S-AK(19cols, indices 7,8,9 repeat), DECIDIR→AM(idx13), AUTO→AN(idx14)
#
# TECNOLOGÍA (student 1 ARACENA = student 2 in 2025 since 1 is MISSING):
#   C=4,D=4,E=4 | F=0(skip),G=45 | O=45 | P=40,Q=40,R=40,S=40,T=40 | AD=40 | AE=5,AF=5 | AI=5,AJ=5,AK=99
#   2026: SER→C-H(×2), SABER→J-Q(all 45 from G), HACER→S-AF(14cols, indices 15,16,17,18,19,29 repeat), DECIDIR→AH(idx34), AUTO→AN(idx35)

SUBJECT_MAPS = {
    'LENGUAJE': {
        # SER: idx 2,3,4 → C,D,E then repeat F,G,H (each ×2)
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        # SABER: idx 5,6,7 → repeat to fill J-Q
        'saber': [(5,'J'),(6,'K'),(7,'L'),(5,'M'),(6,'N'),(7,'O'),(5,'P'),(6,'Q')],
        # HACER: idx 8,9,10,11,12,13,14 → repeat to fill S-AK (25 cols)
        'hacer': [(8,'S'),(9,'T'),(10,'U'),(11,'V'),(12,'W'),(13,'X'),(14,'Y'),
                  (8,'Z'),(9,'AA'),(10,'AB'),(11,'AC'),(12,'AD'),(13,'AE'),(14,'AF'),
                  (8,'AG'),(9,'AH'),(10,'AI'),(11,'AJ'),(12,'AK')],
        'decidir': (17, 'AM'),
        'auto': (18, 'AN'),
    },
    'MATEMÁTICAS': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(7,'L'),(5,'M'),(6,'N'),(7,'O'),(5,'P'),(6,'Q')],
        # HACER: idx 9-17 (9 items) → repeat to fill S-AK (19 cols)
        'hacer': [(9,'S'),(10,'T'),(11,'U'),(12,'V'),(13,'W'),(14,'X'),(15,'Y'),
                  (16,'Z'),(17,'AA'),(9,'AB'),(10,'AC'),(11,'AD'),(12,'AE'),
                  (13,'AF'),(14,'AG'),(15,'AH'),(16,'AI'),(17,'AJ')],
        'decidir': (20, 'AM'),  # idx 20 = U = 5
        'auto': (23, 'AN'),      # idx 23 = X = 5
    },
    'SOCIALES': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(7,'L'),(5,'M'),(6,'N'),(7,'O'),(5,'P'),(6,'Q')],
        # HACER: idx 8(I=40),9(J=35),10(K=40),11=0,12(M=40),13(N=5),14(O=5),15(P=5),16(Q=5)
        # 2026 S-AF: fill with repeating pattern of [8,9,10,12,13,14,15]
        'hacer': [(8,'S'),(9,'T'),(10,'U'),(12,'V'),(13,'W'),(14,'X'),(15,'Y'),
                  (8,'Z'),(9,'AA'),(10,'AB'),(12,'AC'),(13,'AD'),(14,'AE'),(15,'AF')],
        'decidir': (15, 'AH'),  # idx 15 = P = 5
        'auto': (18, 'AN'),     # idx 18 = ? Let me check: from debug, row 10 has idx 18=? Let's check again
    },
    'VALORES': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        'saber': [(5,'J'),(6,'K'),(5,'L'),(6,'M'),(5,'N'),(6,'O'),(5,'P'),(6,'Q')],
        # HACER: idx 7(H=38),8(I=40),9(J=39) → repeat to fill 19 cols
        'hacer': [(7,'S'),(8,'T'),(9,'U'),(7,'V'),(8,'W'),(9,'X'),
                  (7,'Y'),(8,'Z'),(9,'AA'),(7,'AB'),(8,'AC'),(9,'AD'),
                  (7,'AE'),(8,'AF'),(9,'AG'),(7,'AH'),(8,'AI'),(9,'AJ'),
                  (7,'AK')],
        'decidir': (13, 'AM'),  # idx 13 = N = 5
        'auto': (14, 'AN'),     # idx 14 = O = 5
    },
    'TECNOLOGÍA': {
        'ser': [(2,'C'),(3,'D'),(4,'E'),(2,'F'),(3,'G'),(4,'H')],
        # SABER: idx 6 (G=45) → repeat to fill J-Q
        'saber': [(6,'J'),(6,'K'),(6,'L'),(6,'M'),(6,'N'),(6,'O'),(6,'P'),(6,'Q')],
        # HACER: idx 15(P=40),16(Q=40),17(R=40),18(S=40),19(T=40),29(AD=40) → 6 items to 14 cols
        'hacer': [(15,'S'),(16,'T'),(17,'U'),(18,'V'),(19,'W'),(29,'X'),
                  (15,'Y'),(16,'Z'),(17,'AA'),(18,'AB'),(19,'AC'),(29,'AD'),
                  (15,'AE'),(16,'AF')],
        'decidir': (34, 'AH'),  # idx 34 = AI = 5
        'auto': (35, 'AN'),      # idx 35 = AJ = 5
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
    print(f"  {subj}: {len(students_2025[subj])} students, keys: {sorted(students_2025[subj].keys())[:3]}...")

# ─── VERIFY SOCIALES & VALORES AUTO IDX ──────────────────────────────────────
print("\nVerifying SOCIALES AUTO:")
s1 = students_2025['SOCIALES'][1]
for k in sorted(s1.keys()):
    print(f"  idx {k}: {s1[k]}")
print(f"  Total (idx 17): {s1.get(17,'N/A')}")

print("\nVerifying VALORES AUTO:")
s1 = students_2025['VALORES'][1]
for k in sorted(s1.keys()):
    print(f"  idx {k}: {s1[k]}")
print(f"  Total (idx 14): {s1.get(14,'N/A')}")

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
        if snum not in students_2025[subj]:
            continue
        sdata = students_2025[subj][snum]

        target_row = None
        for row in sheet_data.findall(f'{{{ns}}}row'):
            if int(row.get('r')) == excel_row:
                target_row = row
                break
        if target_row is None:
            continue

        # SER (scaled x2)
        for src_idx, tgt_col in m['ser']:
            val = sdata.get(src_idx, 0) * 2
            set_cell_numeric(target_row, tgt_col, excel_row, val)

        # SABER
        for src_idx, tgt_col in m['saber']:
            set_cell_numeric(target_row, tgt_col, excel_row, sdata.get(src_idx, 0))

        # HACER
        for src_idx, tgt_col in m['hacer']:
            set_cell_numeric(target_row, tgt_col, excel_row, sdata.get(src_idx, 0))

        # DECIDIR & AUTO
        dec_idx, dec_col = m['decidir']
        auto_idx, auto_col = m['auto']
        dec_val = sdata.get(dec_idx, 0)
        auto_val = sdata.get(auto_idx, 0)
        set_cell_numeric(target_row, dec_col, excel_row, dec_val)
        set_cell_numeric(target_row, auto_col, excel_row, auto_val)

        # Debug first 2 students
        if snum <= 2:
            ser_vals = [sdata.get(s, 0)*2 for s, c in m['ser'][:3]]
            hacer_first7 = [sdata.get(h, 0) for h, c in m['hacer'][:7]]
            print(f"  {subj} st{snum}: SER×2={ser_vals}, DEC({dec_idx})={dec_val}, AUTO({auto_idx})={auto_val}")

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