import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

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

for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    try:
        s = read_2025_students(full2025, subj)
        keys = list(s.keys())
        print(f"{subj}: {len(s)} students, keys={keys[:5]}...")
        if 1 in s:
            print(f"  Student 1 data: {dict(list(s[1].items())[:5])}")
        else:
            print(f"  WARNING: No student 1! First 3 keys: {keys[:3]}")
    except Exception as e:
        print(f"{subj}: ERROR: {e}")