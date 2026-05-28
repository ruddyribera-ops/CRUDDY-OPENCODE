import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

# For each subject, show the ACTUAL raw data for student 1 and 2 with column indices
for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    df = pd.read_excel(full2025, sheet_name=subj, header=None)
    print(f"\n{'='*60}")
    print(f"SUBJECT: {subj}")

    # Show dimension headers from row 5
    print("Row 5 (dimension labels):")
    row5 = df.iloc[5]
    for j in range(min(40, len(row5))):
        v = row5.iloc[j]
        if pd.notna(v):
            col_letter = chr(65+j) if j < 26 else chr(64+j//26)+chr(65+j%26)
            print(f"  pandas idx {j} = Excel col {col_letter}: '{v}'")

    # Show ALL values for student row 10 with column indices
    print("\nStudent row 10 (ALL values with pandas indices):")
    row10 = df.iloc[10]
    for j in range(min(40, len(row10))):
        v = row10.iloc[j]
        if pd.notna(v):
            col_letter = chr(65+j) if j < 26 else chr(64+j//26)+chr(65+j%26)
            print(f"  pandas idx {j} = Excel col {col_letter}: {v}")

    # Show ALL values for student row 11
    print("\nStudent row 11 (ALL values):")
    row11 = df.iloc[11]
    for j in range(min(40, len(row11))):
        v = row11.iloc[j]
        if pd.notna(v):
            col_letter = chr(65+j) if j < 26 else chr(64+j//26)+chr(65+j%26)
            print(f"  pandas idx {j} = Excel col {col_letter}: {v}")