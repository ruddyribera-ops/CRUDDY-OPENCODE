---
name: textbook-to-pptx
description: Extrae texto de imágenes de libros de texto vía OCR y genera PPTX educativos con diseño pedagógico adaptado por edad.
tags: [education, ocr, pptx, spanish]
---

# Textbook-to-PPTX (L0)

## Overview
Pipeline: Imagen de libro → OCR preprocesado → Plan de slides con Bloom objectives → Auto image fetching → PPTX con progressive disclosure, image labels y data cards.

## When to Use
- Usuario tiene imágenes de páginas de libro de texto y quiere diapositivas para clase
- Usuario menciona grado escolar (ej: "5to primaria")

## Quick Reference

| Necesito... | Cargar archivo |
|-------------|---------------|
| Código de helpers python-pptx (txt, rect, add_img, etc.) | `references/code-helpers.md` |
| Templates de color completos (WARM, PROFESSIONAL, ACADEMIC) | `references/template-system.md` |
| OCR preprocessing + table/diagram handling | `references/ocr-pipeline.md` |
| Patrones: progressive disclosure, image labeling, data cards | `references/progressive-disclosure.md` |
| Validación automática post-generación | `scripts/validate_pptx.py` |

## Mandatory Pre-Flight

**Determinar nivel educativo ANTES de generar. Preguntar si no está especificado.**

| Input | Template | Bloom levels | Max words |
|-------|----------|-------------|-----------|
| "5to primaria", 10-11 años | WARM | 1-4 (Recordar-Analizar) | 80 |
| "secundaria", 12-15 años | PROFESSIONAL | 1-5 (Recordar-Evaluar) | 120 |
| "colegio", 16-18 años | ACADEMIC | 1-6 (Recordar-Crear) | 200 |

## Minimal Procedure

### 0. Bloom Objectives
Definir 4 objetivos de aprendizaje (Recordar, Comprender, Aplicar, Analizar mínimo).
Verbos según edad. Output visible en Slide 1.

### 1. OCR
Leer `references/ocr-pipeline.md` → preprocesar con deskew+CLAHE → Tesseract(lang='spa').

### 2. Plan Slides
Si hay 5+ items o 80+ palabras por tema → activar progressive disclosure (2 slides con fade).
Si hay datos numéricos → usar data cards (icono + número + texto).
Si hay imágenes → image labels + attribution.

### 3. Auto Image Fetch
Leer `references/progressive-disclosure.md` → buscar imágenes por TEMA en Commons API.

### 4. Generate PPTX
Leer `references/code-helpers.md` → usar helpers robustos (txt, rect, add_img, add_fade_transition).

### 5. Validate
Ejecutar: `python scripts/validate_pptx.py output.pptx --grade 5to`

## End-of-Task Checklist (run before declaring done)
```
☐ Bloom objectives en Slide 1 (4 niveles mínimo)
☐ Max 80 palabras/slide (elementary)
☐ 0 párrafos continuos — bullets o data cards
☐ Jerga reemplazada o en glosario (última slide)
☐ Progressive disclosure donde hay 5+ items
☐ Image labels sobre imágenes, no al lado
☐ Attribution presente (CC compliance)
☐ Fade transitions en secuencias multi-slide
☐ Paleta correcta para el nivel
☐ Al menos 1 pregunta/reflexión cada 2 slides
☐ Footer: "Grado - Materia"
☐ Duración estimada en portada
☐ validate_pptx.py pasa todos los checks
```

## Trigger Phrases
- "extrae el contenido de estas páginas"
- "crea diapositivas para la clase"  
- "textbook to pptx"
- "paginas del libro a presentacion"
- "integra todo esto al skill" (upgrade)
## Do Not Use
- General OCR text extraction (use ocr-tools)
- PPT creation from non-textbook sources (use pptx-generator)
- Document scanning without PPT output
- General Spanish text processing
