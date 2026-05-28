import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

path2026 = r"D:\Temp\opencode\reg2026_v2"
files2026 = [f for f in os.listdir(path2026) if '5TO' in f and 'PRIMARIA' in f and f.endswith('.xlsx')]
full2026 = os.path.join(path2026, files2026[0])

sheets = ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']

for sheet in sheets:
    df25 = pd.read_excel(full2025, sheet_name=sheet, header=None)
    df26 = pd.read_excel(full2026, sheet_name=sheet, header=None)

    # Count student rows (rows where col 0 is a number = student number)
    studs25 = df25.iloc[:, 0].apply(lambda x: isinstance(x, (int, float)) and not pd.isna(x))
    studs26 = df26.iloc[:, 0].apply(lambda x: isinstance(x, (int, float)) and not pd.isna(x))

    count25 = studs25.sum()
    count26 = studs26.sum()

    # Get student numbers
    nums25 = sorted(df25.iloc[:, 0][studs25].tolist())
    nums26 = sorted(df26.iloc[:, 0][studs26].tolist())

    match = nums25 == nums26
    print(f"\n{sheet}: 2025={count25} students, 2026={count26} students")
    print(f"  2025 nums: {nums25}")
    print(f"  2026 nums: {nums26}")
    print(f"  Match: {match}")

# Also print full 2025 data for each sheet student rows
print("\n\n=== FULL DATA FOR ALL STUDENTS IN 2025 LENGUAJE ===")
df25_lang = pd.read_excel(full2025, sheet_name='LENGUAJE', header=None)
for i in range(10, 32):
    row = df25_lang.iloc[i]
    vals = {j: v for j, v in enumerate(row) if pd.notna(v)}
    if vals:
        print(f"  Row {i}: {vals}")