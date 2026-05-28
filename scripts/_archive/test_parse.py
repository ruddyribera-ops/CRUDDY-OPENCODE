# -*- coding: utf-8 -*-
import re
import sys
sys.stdout.reconfigure(encoding='utf-8')

content = '''UNIDAD 5: INTELIGENCIA ARTIFICIAL APLICADA
Semana 15 (11/05 - 15/05)
Clase 5.1: Machine Learning basico
Semana 16 (18/05 - 22/05)
Clase 5.2: Entrenamiento de un modelo
Semana 17 (25/05 - 29/05)
Clase 5.3: Proyectos con IA

UNIDAD 6: ROBOTICA AVANZADA
Semana 18 (01/06 - 05/06)
Clase 6.1: Sensores avanzados
Semana 19 (08/06 - 12/06)
Clase 6.2: Algoritmos de navegacion
Semana 20 (15/06 - 19/06)
Clase 6.3: Proyecto de robotica
Semana 21 (22/06 - 26/06)
Clase 6.4: Evaluacion del modulo

UNIDAD 7: DESARROLLO WEB BASICO
Semana 22 (29/06 - 03/07)
Clase 7.1: HTML y CSS basico
*** VACACIONES DE INVIERNO - Semana 23 y 24 (Julio 7-17) ***

Semana 25 (20/07 - 24/07)
Clase 7.2: JavaScript intro
Semana 26 (27/07 - 01/08)
Clase 7.3: Proyecto web

UNIDAD 8: PROYECTO FINAL INTEGRADOR
Semana 27 (04/08 - 08/08)
Clase 8.1: Planificacion del proyecto
Semana 28 (11/08 - 15/08)
Clase 8.2: Desarrollo e implementacion
Semana 29 (18/08 - 22/08)
Clase 8.3: Presentacion y evaluacion
Semana 30 (25/08 - 28/08)
Reflexion final y cierre del ano escolar.'''

# Split by week markers
parts = re.split(r'(Semana \d+ \(.*?\))', content)

weeks = {}
current_unit = ''
i = 1
while i < len(parts) - 1:
    week_header = parts[i].strip()
    week_content = parts[i+1].strip() if i+1 < len(parts) else ''

    # Extract week number
    m = re.search(r'Semana (\d+)', week_header)
    if m:
        wn = int(m.group(1))

        # Clean up content
        clean_lines = []
        for line in week_content.split('\n'):
            line = line.strip()
            if not line:
                continue
            if re.match(r'^[\*]+', line):
                continue
            if re.match(r'^UNIDAD \d+:', line):
                current_unit = line
                continue
            clean_lines.append(line)

        weeks[wn] = {
            'header': week_header,
            'unit': current_unit,
            'content': '\n'.join(clean_lines)
        }
    i += 2

# Add vacaciones
for w in [23, 24]:
    weeks[w] = {
        'header': f'Semana {w} (--/-- - --/--)',
        'unit': 'VACACIONES',
        'content': '*** VACACIONES DE INVIERNO ***'
    }

for w in sorted(weeks.keys()):
    print(f'=== Semana {w} ===')
    print(f'Unit: {weeks[w]["unit"]}')
    print(f'Content: {weeks[w]["content"][:80]}')
    print()