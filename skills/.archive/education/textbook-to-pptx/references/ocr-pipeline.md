# ocr-pipeline.md — OCR Preprocessing + Table Handling

## Pipeline Condicional

**⚠️ IMPORTANTE**: El preprocessing NO siempre mejora el OCR. Para imágenes de libro escaneado (buen contraste, blanco y negro), el preprocessing puede EMPEORAR el resultado. Para fotos con poca luz, inclinadas o borrosas, SÍ ayuda.

**Siempre probar ambas versiones y elegir la mejor.**

```python
import cv2
import numpy as np
import pytesseract
from PIL import Image

def preprocess_ocr(image_path):
    """Preprocesamiento CONDICIONAL. Devuelve imagen procesada."""
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"No se pudo leer: {image_path}")
    
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # Estimar calidad: si ya tiene buen contraste, saltar pasos agresivos
    mean_brightness = gray.mean()
    contrast = gray.std()
    
    if contrast > 60:  # ya tiene buen contraste
        # Solo denoise ligero + deskew
        denoised = cv2.medianBlur(gray, 3)
        # Deskew
        coords = np.column_stack(np.where(denoised > 0))
        if len(coords) > 0:
            angle = cv2.minAreaRect(coords)[-1]
            if abs(angle) > 0.5:  # solo si está torcida
                if angle < -45: angle = 90 + angle
                h, w = denoised.shape
                matrix = cv2.getRotationMatrix2D((w // 2, h // 2), angle, 1.0)
                denoised = cv2.warpAffine(denoised, matrix, (w, h), borderValue=255)
        return denoised
    else:  # bajo contraste = foto con poca luz
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        denoised = cv2.medianBlur(enhanced, 3)
        _, binary = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        # Deskew
        coords = np.column_stack(np.where(binary > 0))
        if len(coords) > 0:
            angle = cv2.minAreaRect(coords)[-1]
            if abs(angle) > 0.5:
                if angle < -45: angle = 90 + angle
                h, w = binary.shape
                matrix = cv2.getRotationMatrix2D((w // 2, h // 2), angle, 1.0)
                binary = cv2.warpAffine(binary, matrix, (w, h), borderValue=255)
        return binary

def best_ocr(image_path):
    """Prueba raw y processed, devuelve el mejor resultado."""
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # Raw
    text_raw = pytesseract.image_to_string(gray, lang='spa')
    raw_words = len([w for w in text_raw.split() if len(w) > 2])
    
    # Processed
    processed = preprocess_ocr(image_path)
    text_proc = pytesseract.image_to_string(processed, lang='spa')
    proc_words = len([w for w in text_proc.split() if len(w) > 2])
    
    # Elegir el que más palabras válidas extrajo
    if raw_words >= proc_words:
        return text_raw, 'raw'
    return text_proc, 'processed'
```

## Problema: Tablas y diagramas

### Síntoma
Tesseract linealiza el contenido de tablas. Una celda en la fila 2, columna 1 aparece DESPUÉS de la fila 1, columna 3. El orden de lectura se pierde.

### Detección
```python
def has_table_structure(text):
    """Detecta si el OCR probablemente leyó una tabla."""
    indicators = [
        len([l for l in text.split('\n') if '  ' in l]) > 3,  # múltiples espacios
        sum(1 for c in text if c in '|│─┌┐└┘├┤┬┴┼') > 5,       # caracteres de tabla
        len([l for l in text.split('\n') if l.strip() and len(l.split()) >= 4]) > 5,
    ]
    return sum(indicators) >= 2
```

### Mitigación para tablas
```python
def extract_table_structure(processed_img):
    """Usa OpenCV para detectar líneas de tabla y extraer celdas."""
    # Detectar líneas horizontales y verticales
    horizontal = cv2.morphologyEx(processed_img, cv2.MORPH_OPEN,
                                   np.ones((1, 50), np.uint8))
    vertical = cv2.morphologyEx(processed_img, cv2.MORPH_OPEN,
                                 np.ones((50, 1), np.uint8))
    # Combinar
    table_lines = cv2.bitwise_or(horizontal, vertical)
    
    # Encontrar contornos de celdas
    contours, _ = cv2.findContours(table_lines, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    # ... extraer cada celda y OCR individualmente ...
    # Devuelve lista de (texto_celda, fila, columna)
```

### Mitigación para diagramas/mapas
```python
def is_diagram(processed_img):
    """Detecta si la imagen es principalmente un diagrama/mapa."""
    # Ratio de bordes vs área de texto
    edges = cv2.Canny(processed_img, 50, 150)
    edge_ratio = np.sum(edges > 0) / edges.size
    return edge_ratio > 0.15  # muchos bordes = probable diagrama
```

## Post-procesamiento

```python
import re

def clean_ocr_text(text):
    """Corrige errores comunes de OCR en español."""
    replacements = {
        '0': 'O', '1': 'l', '5': 'S', '6': 'G',
        'clara': 'clara', 'bien': 'bien',
    }
    # Unir líneas cortadas por saltos de línea en mitad de palabra
    text = re.sub(r'(\w)-\n(\w)', r'\1\2', text)
    # Eliminar líneas de solo números (probables números de página)
    text = re.sub(r'\n\d+\n', '\n', text)
    return text.strip()
```

## Orden de lectura (columnas)

Si el texto tiene 2 columnas, Tesseract mezcla izquierda y derecha:

```python
def extract_columns(image_path):
    """Divide imagen en columnas y OCR cada una por separado."""
    img = cv2.imread(image_path)
    h, w = img.shape[:2]
    mid = w // 2
    col1 = img[:, :mid]
    col2 = img[:, mid:]
    
    text1 = pytesseract.image_to_string(preprocess_ocr_from_array(col1), lang='spa')
    text2 = pytesseract.image_to_string(preprocess_ocr_from_array(col2), lang='spa')
    
    return f"{text1}\n\n{text2}"  # columna izquierda primero
```

## Verificación rápida

```bash
# Probar OCR directo
tesseract pagina.jpg stdout -l spa

# Ver calidad del preprocessing
python -c "
import cv2
img = cv2.imread('pagina.jpg')
print(f'Dimension: {img.shape}')
print(f'Brillo medio: {img.mean():.0f}')
print(f'B/N ratio: {len(img[img>128])/img.size:.0%}')
"
```
