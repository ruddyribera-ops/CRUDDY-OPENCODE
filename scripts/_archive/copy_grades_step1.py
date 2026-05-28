import pandas as pd
import zipfile
import shutil
import os
import xml.etree.ElementTree as ET
from copy import deepcopy

# Paths
path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

path2026_base = r"D:\Temp\opencode\reg2026_v2"
files2026 = [f for f in os.listdir(path2026_base) if '5TO' in f and 'PRIMARIA' in f and f.endswith('.xlsx')]
src2026 = os.path.join(path2026_base, files2026[0])

out_dir = r"D:\Temp\opencode\reg2026_output"
if os.path.exists(out_dir):
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

# Copy 2026 to output
shutil.copy2(src2026, os.path.join(out_dir, "5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026.xlsx"))

# Unpack
unpack_dir = os.path.join(out_dir, "unpacked")
with zipfile.ZipFile(src2026, 'r') as z:
    z.extractall(unpack_dir)

ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

# Sheet mappings
sheet_map = {
    'LENGUAJE': 2, 'MATEMÁTICAS': 9, 'SOCIALES': 6, 'VALORES': 7, 'TECNOLOGÍA': 10
}

# 2025→2026 column mapping per subject
# Format: {sheet_name: {2025_col_idx: 2026_col_letter}}
# For each subject, list (2025_col, 2026_col) pairs
col_maps = {
    'LENGUAJE': {
        2025: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
        2026: ['C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH', 'AI', 'AJ', 'AK', 'AM', 'AN']
    },
    'MATEMÁTICAS': {
        2025: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24],
        2026: ['C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD', 'AE', 'AF', 'AG', 'AH', 'AI', 'AJ', 'AK', 'AM', 'AN']
    }
}

# Let me read each 2025 subject and get all student data
def get_2025_student_data(full2025, sheet_name):
    """Read 2025 sheet, return list of dicts {col_idx: value} for each student"""
    df = pd.read_excel(full2025, sheet_name=sheet_name, header=None)
    students = []
    for i in range(10, 35):  # Check rows 10-34
        row = df.iloc[i]
        num = row.iloc[0]
        if isinstance(num, (int, float)) and not pd.isna(num) and 1 <= num <= 30:
            data = {}
            for j in range(len(row)):
                v = row.iloc[j]
                if pd.notna(v) and isinstance(v, (int, float)):
                    data[j] = v
            students.append(data)
    return students

# Get 2025 data for all subjects
subjects_2025 = {
    'LENGUAJE': 'LENGUAJE',
    'MATEMÁTICAS': 'MATEMÁTICAS',
    'SOCIALES': 'SOCIALES',
    'VALORES': 'VALORES',
    'TECNOLOGÍA': 'TECNOLOGÍA'
}

data_2025 = {}
for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    data_2025[subj] = get_2025_student_data(full2025, subj)
    print(f"{subj}: {len(data_2025[subj])} students from 2025")

print("\n2025 LENGUAJE student 1:", data_2025['LENGUAJE'][0] if data_2025['LENGUAJE'] else "NONE")
print("\n2025 MATEMÁTICAS student 1:", data_2025['MATEMÁTICAS'][0] if data_2025['MATEMÁTICAS'] else "NONE")