import pandas as pd
import os

path2025 = r"D:\Temp\opencode\reg2025\REGISTROS PEDAGÓGICOS 2025\NIVEL PRIMARIO\1ER TRIMESTRE"
f2025 = [f for f in os.listdir(path2025) if '4' in f and 'PRIMARIA' in f][0]
full2025 = os.path.join(path2025, f2025)

path2026 = r"D:\Temp\opencode\reg2026_v2"
files2026 = [f for f in os.listdir(path2026) if '5TO' in f and 'PRIMARIA' in f and f.endswith('.xlsx')]
full2026 = os.path.join(path2026, files2026[0])

sheets_to_check = ['LENGUAJE', 'MATEMÁTICAS', 'SOCIALES', 'VALORES', 'TECNOLOGÍA']

for sheet in sheets_to_check:
    print(f"\n{'='*70}")
    print(f"SHEET: {sheet}")
    print(f"{'='*70}")

    df25 = pd.read_excel(full2025, sheet_name=sheet, header=None)
    df26 = pd.read_excel(full2026, sheet_name=sheet, header=None)

    print(f"2025 shape: {df25.shape}, 2026 shape: {df26.shape}")

    print(f"\n--- 2025 HEADER ROWS (0-8) ---")
    # Show non-NaN content in rows 0-8
    for i in range(9):
        row = df25.iloc[i]
        non_nan = [(j, v) for j, v in enumerate(row) if pd.notna(v)]
        if non_nan:
            print(f"  Row {i}: {non_nan}")

    print(f"\n--- 2025 STUDENT ROW (row 10) ---")
    row10 = df25.iloc[10]
    non_nan_10 = [(j, v) for j, v in enumerate(row10) if pd.notna(v)]
    print(f"  {non_nan_10}")

    print(f"\n--- 2026 HEADER ROWS (0-8) ---")
    for i in range(9):
        row = df26.iloc[i]
        non_nan = [(j, v) for j, v in enumerate(row) if pd.notna(v)]
        if non_nan:
            print(f"  Row {i}: {non_nan}")

    print(f"\n--- 2026 STUDENT ROW (row 10) ---")
    row10_26 = df26.iloc[10]
    non_nan_10_26 = [(j, v) for j, v in enumerate(row10_26) if pd.notna(v)]
    print(f"  {non_nan_10_26}")