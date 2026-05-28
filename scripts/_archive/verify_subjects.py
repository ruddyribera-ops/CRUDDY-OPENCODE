"""
Simple verification: show exact values at specific indices for each subject.
"""
import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

# For each subject, show ALL non-NaN values for student rows 10 and 11
# with their pandas indices and Excel column letters

def idx_to_col(j):
    if j < 26:
        return chr(65+j)
    return chr(64+j//26) + chr(65+j%26)

for subj in ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']:
    df = pd.read_excel(full2025, sheet_name=subj, header=None)
    print(f"\n{'='*60}")
    print(f"SUBJECT: {subj}")
    print(f"{'='*60}")

    # Row 5 (header) and row 6 (criteria)
    print("\nRow 5 (header):")
    row5 = df.iloc[5]
    for j in range(min(40, len(row5))):
        v = row5.iloc[j]
        if pd.notna(v):
            print(f"  idx={j} col={idx_to_col(j)}: {repr(v)[:50]}")

    print("\nRow 6 (criteria):")
    row6 = df.iloc[6]
    for j in range(min(40, len(row6))):
        v = row6.iloc[j]
        if pd.notna(v):
            print(f"  idx={j} col={idx_to_col(j)}: {repr(v)[:50]}")

    # Student row 10
    print("\nRow 10 (student 1 - ARACENA):")
    row10 = df.iloc[10]
    for j in range(min(40, len(row10))):
        v = row10.iloc[j]
        if pd.notna(v):
            print(f"  idx={j} col={idx_to_col(j)}: {v}")

    # Student row 11
    print("\nRow 11 (student 2 - BONILLA):")
    row11 = df.iloc[11]
    for j in range(min(40, len(row11))):
        v = row11.iloc[j]
        if pd.notna(v):
            print(f"  idx={j} col={idx_to_col(j)}: {v}")