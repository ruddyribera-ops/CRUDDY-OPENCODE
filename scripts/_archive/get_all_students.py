import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    df = pd.read_excel(full2025, sheet_name=subj, header=None)
    print(f"\n{'='*60}")
    print(f"SUBJECT: {subj}")

    # Find all student rows
    students = []
    for i in range(9, min(40, len(df))):
        row = df.iloc[i]
        num = row.iloc[0]
        if isinstance(num, (int, float)) and not pd.isna(num) and 1 <= num <= 30:
            data = {}
            for j in range(len(row)):
                v = row.iloc[j]
                if pd.notna(v) and isinstance(v, (int, float)):
                    data[j] = v
            students.append(data)

    print(f"  Total students: {len(students)}")
    print(f"  Student numbers: {[int(s[0]) for s in students]}")
    # Show student 1 data
    print(f"  Student 1: {students[0]}")
    # Show student 2 data
    print(f"  Student 2: {students[1]}")