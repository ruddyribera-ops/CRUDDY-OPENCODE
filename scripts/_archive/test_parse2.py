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

# Find all unit headers and their starting positions
unit_pattern = re.compile(r'^UNIDAD (\d+): (.+)$', re.MULTILINE)
units = [(m.start(), m.group(1), m.group(2)) for m in unit_pattern.finditer(content)]

# Find all week markers and their positions
week_pattern = re.compile(r'^Semana (\d+) \((\d+/\d+ - \d+/\d+)\)$', re.MULTILINE)
weeks = [(m.start(), int(m.group(1)), m.group(2)) for m in week_pattern.finditer(content)]

print("Units found:")
for u in units:
    print(f"  pos={u[0]}, num={u[1]}, name={u[2]}")

print("\nWeeks found:")
for w in weeks:
    print(f"  pos={w[0]}, num={w[1]}, dates={w[2]}")

# For each week, find which unit it belongs to
def find_unit(week_pos):
    for i in range(len(units)-1, -1, -1):
        if units[i][0] < week_pos:
            return f"UNIDAD {units[i][1]}: {units[i][2]}"
    return ''

print("\nParsed weeks:")
for w in weeks:
    wn = w[1]
    wdate = w[2]
    wpos = w[0]
    unit = find_unit(wpos)
    print(f"  Semana {wn} ({wdate}) -> {unit}")