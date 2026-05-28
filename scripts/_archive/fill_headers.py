"""
Fill CRITERIOS DE EVALUACIÓN and INSTRUMENTOS Y/O ESTRATEGIAS DE EVALUACIÓN
in the 2026 registro pedagogico from PDC documents.

Structure per sheet:
- Row 7: CRITERIOS DE EVALUACIÓN in B, PROMEDIO in average cols (I, R, AL/AG)
- Row 8: INSTRUMENTOS Y/O ESTRATEGIAS in B, Cuestionario in AUTO col
- Rows 7+ for C-H: SER criteria
- Rows 7+ for J-Q: SABER criteria
- Rows 7+ for S-AK/S-AF: HACER criteria
"""

import zipfile
import shutil
import os
import xml.etree.ElementTree as ET

src = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"
out_path = r"C:\Users\Windows\Desktop\5TO PRIMARIA - 1ER TRIM REGISTRO PEDAGOGICO-LPS 2026 (filled).xlsx"

out_dir = r"D:\Temp\opencode\fill_headers"
if os.path.exists(out_dir):
    shutil.rmtree(out_dir)
os.makedirs(out_dir)

shutil.copy2(src, os.path.join(out_dir, "tmp_src.xlsx"))
with zipfile.ZipFile(os.path.join(out_dir, "tmp_src.xlsx"), 'r') as z:
    z.extractall(out_dir)

ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'

sheet_map = {
    'LENGUAJE': 2,
    'MATEMÁTICAS': 9,
    'SOCIALES': 6,
    'VALORES': 7,
    'TECNOLOGÍA': 10
}

# ─── CRITERIA & INSTRUMENTS FROM PDC ──────────────────────────────────────────
# Extracted from PDC documents

# LENGUAJE (from Unidad 1 PDC 2026)
LENGUAJE_SER = [
    "Aprecia la importancia de las narraciones de mitos en la tradición oral boliviana y de otros pueblos.",
    "Reconoce la importancia del respeto para convivir con los demás y llegar a consensos.",
    "Valora la importancia de los elementos que intervienen en la comunicación."
]
LENGUAJE_SABER = [
    "Comprende el texto 'Guedé pinta a los animales' en los diferentes niveles de la comprensión lectora.",
    "Aprende las características de los mitos y de la mitología de diferentes pueblos.",
    "Identifica las estrategias para realizar una exposición oral efectiva."
]
LENGUAJE_HACER = [
    "Expresa ideas de manera clara mediante exposiciones orales sobre temas studied.",
    "Elabora resúmenes narrativos con coherencia y uso adecuado del lenguaje.",
    "Participa activamente en actividades de comprensión y producción escrita."
]
LENGUAJE_INSTRUMENTOS = [
    "Lectura comprensiva del mito 'Guedé pinta a los animales'.",
    "Exposición oral sobre temas de mitología.",
    "Elaboración de resúmenes narrativos.",
    "Cuestionario de autoevaluación."
]

# MATEMÁTICAS (from Unidades 1-3 PDC 2026)
MATEMATICAS_SER = [
    "Demuestra responsabilidad y compromiso en el desarrollo de las actividades matemáticas.",
    "Valora la importancia de reforzar los conocimientos adquiridos.",
    "Manifiesta respeto por las ideas y ritmos de aprendizaje de sus compañeros.",
    "Participa activamente en trabajos individuales y grupales."
]
MATEMATICAS_SABER = [
    "Reconoce figuras y cuerpos geométricos, identificando sus principales características.",
    "Comprende los conceptos de múltiplos, submúltiplos y divisores.",
    "Identifica los términos y propiedades de la suma, resta y multiplicación.",
    "Comprende la aplicación de las operaciones en contextos reales."
]
MATEMATICAS_HACER = [
    "Resuelve ejercicios de suma, resta, multiplicación y división con agilidad.",
    "Aplica correctamente los conocimientos matemáticos en problemas contextualizados.",
    "Utiliza estrategias adecuadas para la resolución de situaciones planteadas.",
    "Presenta cuaderno de apuntes con ejercicios desarrollados."
]
MATEMATICAS_INSTRUMENTOS = [
    "Cuaderno de apuntes y ejercicios.",
    "Resolución de problemas contextualizados.",
    "Evaluaciones formativas y sumativas.",
    "Cuestionario de autoevaluación."
]

# SOCIALES (from Unidad 1 PDC 2026)
SOCIALES_SER = [
    "Valora la historia de los pueblos y las expresiones culturales.",
    "Demuestra respeto por los hechos históricos y por quienes participaron.",
    "Reconoce la importancia de entender los hechos para comprender a las personas.",
    "Fomenta la reflexión sobre el patrimonio cultural boliviano."
]
SOCIALES_SABER = [
    "Reconoce qué es la historia y cuáles son sus elementos más importantes.",
    "Identifica los tiempos de la historia y la memoria histórica.",
    "Diferencia los tipos de fuentes a partir de los cuales se construye la historia.",
    "Comprende la importancia de las misiones de Chiquitos como patrimonio."
]
SOCIALES_HACER = [
    "Relata la vida y acciones de héroes y heroínas de la historia boliviana.",
    "Redacta textos sobre la historia, los héroes y los valores transmitidos.",
    "Participa en debates sobre hechos y personajes históricos.",
    "Elabora líneas de tiempo y cuadros comparativos."
]
SOCIALES_INSTRUMENTOS = [
    "Texto sobre Las Misiones de Chiquitos.",
    "Línea de tiempo y cuadro comparativo.",
    "Debate sobre hechos históricos.",
    "Cuestionario de autoevaluación."
]

# VALORES (from Trimestre 1 PDC 2026 - Ed. Socioemocional)
VALORES_SER = [
    "Reconoce y valora sus características únicas y las de sus compañeros.",
    "Demuestra una actitud positiva y flexible frente a cambios y adversidades.",
    "Practica el respeto y la empatía en sus relaciones interpersonales.",
    "Valora la importancia de expresar sus emociones de forma asertiva."
]
VALORES_SABER = [
    "Identifica cómo las preocupaciones afectan su capacidad de atención.",
    "Reconoce sus propias fortalezas y áreas de mejora.",
    "Comprende la importancia de la autorregulación emocional.",
    "Diferencia entre reacciones reactivas, pasivas y asertivas."
]
VALORES_HACER = [
    "Aplica técnicas de relajación y concentración para liberar la mente.",
    "Relaciona emociones con sensaciones corporales para fortalecer la autoconciencia.",
    "Redacta textos personales sobre su identidad y valores.",
    "Crea tablas y manuales para mejorar la convivencia."
]
VALORES_INSTRUMENTOS = [
    "Texto personal sobre lo que le hace único y especial.",
    "Tabla de clasificación de emociones y reacciones.",
    "Manual del Buen Trato elaborado en equipo.",
    "Cuestionario de autoevaluación."
]

# TECNOLOGÍA (same as 2025 - Responsability, Order, Respect in SER; tecnología info)
TECNOLOGÍA_SER = [
    "Demuestra responsabilidad en el uso de equipos y materiales.",
    "Mantiene el orden y limpieza en el espacio de trabajo.",
    "Respeta las normas de seguridad en la sala de computo.",
    "Colabora con sus compañeros en actividades tecnológicas."
]
TECNOLOGÍA_SABER = [
    "Comprende qué es la tecnología de la información y su importancia.",
    "Identifica cómo la tecnología nos ayuda en el aprendizaje.",
    "Reconoce la tecnología de la información en la escuela y la vida diaria.",
    "Distingue qué es tecnología de información y qué no lo es."
]
TECNOLOGÍA_HACER = [
    "Elabora fichas de trabajo sobre temas tecnológicos.",
    "Crea posters de seguridad en el uso de equipos.",
    "Participa en actividades prácticas de tecnología.",
    "Resuelve ejercicios y prácticas en el aula de computación."
]
TECNOLOGÍA_INSTRUMENTOS = [
    "Ficha de trabajo sobre tecnología de la información.",
    "Poster de seguridad en sala de computo.",
    "Prácticas en aula de computación.",
    "Cuestionario de autoevaluación."
]

# ─── HELPER FUNCTIONS ─────────────────────────────────────────────────────────

def add_string(strings_list, new_str):
    """Add a string to shared strings, return its index"""
    if new_str in strings_list:
        return strings_list.index(new_str)
    strings_list.append(new_str)
    return len(strings_list) - 1

def set_cell_string(row_elem, col_letter, row_num, str_idx, style='0'):
    """Set a cell to a shared string value"""
    cell_ref = f"{col_letter}{row_num}"
    cell = row_elem.find(f'{{{ns}}}c[@r="{cell_ref}"]')
    if cell is None:
        cell = ET.SubElement(row_elem, f'{{{ns}}}c')
        cell.set('r', cell_ref)
    cell.set('t', 's')
    cell.set('s', style)
    v_elem = cell.find(f'{{{ns}}}v')
    if v_elem is None:
        v_elem = ET.SubElement(cell, f'{{{ns}}}v')
    v_elem.text = str(str_idx)
    # Remove formula if any
    f_elem = cell.find(f'{{{ns}}}f')
    if f_elem is not None:
        cell.remove(f_elem)

def set_cell_inline(row_elem, col_letter, row_num, text, style='0'):
    """Set a cell to an inline string (preserves spaces/newlines)"""
    cell_ref = f"{col_letter}{row_num}"
    cell = row_elem.find(f'{{{ns}}}c[@r="{cell_ref}"]')
    if cell is None:
        cell = ET.SubElement(row_elem, f'{{{ns}}}c')
        cell.set('r', cell_ref)
    cell.set('t', 'inlineStr')
    cell.set('s', style)
    # Remove old content
    for child in list(cell):
        cell.remove(child)
    is_elem = ET.SubElement(cell, f'{{{ns}}}is')
    t_elem = ET.SubElement(is_elem, f'{{{ns}}}t')
    t_elem.text = text
    if t_elem.text:
        t_elem.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')

def col_num_to_letter(n):
    """Convert 1-based column number to letter"""
    result = ''
    while n > 0:
        n, remainder = divmod(n - 1, 26)
        result = chr(65 + remainder) + result
    return result

def letter_to_col_num(s):
    """Convert column letter to 1-based number"""
    result = 0
    for c in s.upper():
        result = result * 26 + (ord(c) - ord('A') + 1)
    return result

# ─── LOAD SHARED STRINGS ──────────────────────────────────────────────────────
ss_path = os.path.join(out_dir, 'xl', 'sharedStrings.xml')
ss_tree = ET.parse(ss_path)
ss_root = ss_tree.getroot()

strings = []
for si in ss_root.findall(f'{{{ns}}}si'):
    t_elems = si.findall(f'.//{{{ns}}}t')
    text = ''.join(t.text or '' for t in t_elems)
    strings.append(text)

print(f"Loaded {len(strings)} shared strings")

# ─── ADD NEW STRINGS ───────────────────────────────────────────────────────────
# Add all our criteria strings
criteria_data = {
    'LENGUAJE': (LENGUAJE_SER, LENGUAJE_SABER, LENGUAJE_HACER, LENGUAJE_INSTRUMENTOS),
    'MATEMÁTICAS': (MATEMATICAS_SER, MATEMATICAS_SABER, MATEMATICAS_HACER, MATEMATICAS_INSTRUMENTOS),
    'SOCIALES': (SOCIALES_SER, SOCIALES_SABER, SOCIALES_HACER, SOCIALES_INSTRUMENTOS),
    'VALORES': (VALORES_SER, VALORES_SABER, VALORES_HACER, VALORES_INSTRUMENTOS),
    'TECNOLOGÍA': (TECNOLOGÍA_SER, TECNOLOGÍA_SABER, TECNOLOGÍA_HACER, TECNOLOGÍA_INSTRUMENTOS),
}

# Flatten to add all
all_criteria = {}
for subj, (ser, saber, hacer, instr) in criteria_data.items():
    all_criteria[subj] = {}
    for cat, items in [('ser', ser), ('saber', saber), ('hacer', hacer), ('instr', instr)]:
        idxs = []
        for item in items:
            idxs.append(add_string(strings, item))
        all_criteria[subj][cat] = idxs

# Write updated shared strings
ss_root.clear()
for text in strings:
    si = ET.SubElement(ss_root, f'{{{ns}}}si')
    t = ET.SubElement(si, f'{{{ns}}}t')
    t.text = text or ''
    t.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')

print(f"Updated to {len(strings)} shared strings")

# ─── COLUMN RANGES PER SUBJECT ─────────────────────────────────────────────────
# SER: C(3) to H(8) = 6 cols
# SABER: J(10) to Q(17) = 8 cols
# HACER: S(19) to AK(37) = 19 cols (Lengua/Mate/Valores)
# HACER: S(19) to AF(32) = 14 cols (Sociales/Tecnología)
# AUTO: AM(39) = 1 col

SUBJECT_COLS = {
    'LENGUAJE': {'ser': (3, 8), 'saber': (10, 17), 'hacer': (19, 37), 'auto_col': 39},
    'MATEMÁTICAS': {'ser': (3, 8), 'saber': (10, 17), 'hacer': (19, 37), 'auto_col': 39},
    'SOCIALES': {'ser': (3, 8), 'saber': (10, 17), 'hacer': (19, 32), 'auto_col': 34},
    'VALORES': {'ser': (3, 8), 'saber': (10, 17), 'hacer': (19, 37), 'auto_col': 39},
    'TECNOLOGÍA': {'ser': (3, 8), 'saber': (10, 17), 'hacer': (19, 32), 'auto_col': 34},
}

# Style for header rows (copy from existing cell style)
# Use style index 3 (typical string style)
HEADER_STYLE = '3'

# ─── FILL EACH SHEET ────────────────────────────────────────────────────────────
for subj, sheet_num in sheet_map.items():
    sheet_path = os.path.join(out_dir, 'xl', 'worksheets', f'sheet{sheet_num}.xml')
    tree = ET.parse(sheet_path)
    root = tree.getroot()
    sheet_data = root.find(f'{{{ns}}}sheetData')

    # Find rows 7 and 8
    row7 = None
    row8 = None
    for row in sheet_data.findall(f'{{{ns}}}row'):
        r = int(row.get('r'))
        if r == 7:
            row7 = row
        elif r == 8:
            row8 = row

    if row7 is None:
        print(f"  WARNING: Row 7 not found in {subj}")
        continue

    cols = SUBJECT_COLS[subj]
    ser_range = cols['ser']
    saber_range = cols['saber']
    hacer_range = cols['hacer']
    auto_col = cols['auto_col']

    criteria = all_criteria[subj]

    # ── Fill SER criteria in row 7, columns C-H ──
    ser_items = criteria['ser']
    for i, col_num in enumerate(range(ser_range[0], ser_range[1] + 1)):
        col_letter = col_num_to_letter(col_num)
        if i < len(ser_items):
            str_idx = ser_items[i]
            set_cell_string(row7, col_letter, 7, str_idx, HEADER_STYLE)

    # ── Fill SABER criteria in row 7, columns J-Q ──
    saber_items = criteria['saber']
    for i, col_num in enumerate(range(saber_range[0], saber_range[1] + 1)):
        col_letter = col_num_to_letter(col_num)
        if i < len(saber_items):
            str_idx = saber_items[i]
            set_cell_string(row7, col_letter, 7, str_idx, HEADER_STYLE)

    # ── Fill HACER criteria in row 7, columns S-AK/AF ──
    hacer_items = criteria['hacer']
    for i, col_num in enumerate(range(hacer_range[0], hacer_range[1] + 1)):
        col_letter = col_num_to_letter(col_num)
        if i < len(hacer_items):
            str_idx = hacer_items[i]
            set_cell_string(row7, col_letter, 7, str_idx, HEADER_STYLE)

    # ── Fill INSTRUMENTOS in row 8 ──
    if row8 is not None:
        instr_items = criteria['instr']
        # Instruments go in SER/SABER/HACER columns in row 8
        ser_instr_count = min(len(ser_items), ser_range[1] - ser_range[0] + 1)
        for i in range(ser_instr_count):
            col_num = ser_range[0] + i
            col_letter = col_num_to_letter(col_num)
            if i < len(instr_items):
                set_cell_string(row8, col_letter, 8, instr_items[i], HEADER_STYLE)

        instr_idx = ser_instr_count
        for i in range(len(saber_items)):
            col_num = saber_range[0] + i
            col_letter = col_num_to_letter(col_num)
            if instr_idx < len(instr_items):
                set_cell_string(row8, col_letter, 8, instr_items[instr_idx], HEADER_STYLE)
                instr_idx += 1

    print(f"  {subj}: SER({len(ser_items)}), SABER({len(saber_items)}), HACER({len(hacer_items)}), INSTR({len(instr_items)}) done")

    # Write sheet
    tree.write(sheet_path, xml_declaration=True, encoding='UTF-8')

# Write shared strings
ss_tree.write(ss_path, xml_declaration=True, encoding='UTF-8')

# ─── REPACK ──────────────────────────────────────────────────────────────────
print("\nRepacking...")
repack_path = os.path.join(out_dir, "repacked.zip")
with zipfile.ZipFile(repack_path, 'w', zipfile.ZIP_DEFLATED) as zout:
    for root_dir, dirs, files in os.walk(out_dir):
        for file in files:
            file_path = os.path.join(root_dir, file)
            arcname = os.path.relpath(file_path, out_dir)
            if arcname == 'tmp_src.xlsx' or arcname == 'repacked.zip':
                continue
            zout.write(file_path, arcname)

shutil.copy2(repack_path, out_path)
print(f"\nDone! Output: {out_path}")