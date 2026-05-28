import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

def read_students(full2025, sheet_name):
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

for subj in ['SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    df = pd.read_excel(full2025, sheet_name=subj, header=None)

    # Show row 6 (criteria) for these subjects
    print(f"\n{subj} row 6 (criteria/instrument headers):")
    row6 = df.iloc[6]
    for j in range(min(40, len(row6))):
        v = row6.iloc[j]
        if pd.notna(v):
            col = chr(65+j) if j < 26 else chr(64+j//26)+chr(65+j%26)
            print(f"  idx={j} col={col}: {repr(v)[:60]}")

    s1 = read_students(full2025, subj)[1]
    print(f"\n{subj} student 1 ALL values:")
    for k in sorted(s1.keys()):
        col = chr(65+k) if k < 26 else chr(64+k//26)+chr(65+k%26)
        print(f"  idx={k} col={col}: {s1[k]}")