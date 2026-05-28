# -*- coding: utf-8 -*-
import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, r'D:\Temp\opencode')
from generate_tech_weekly import parse_pdc, get_pdc_path

pdc = get_pdc_path('1P')
print('PDC path: ' + pdc)
weeks = parse_pdc(pdc)
for w in [15, 16, 23, 24]:
    if w in weeks:
        print('Semana ' + str(w) + ':')
        print('  unit: ' + weeks[w]['unit'])
        print('  content: ' + weeks[w]['content'][:100])
        print()