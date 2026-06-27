---
name: ocr-tools
description: OCR tools comparison and pipelines — Tesseract, EasyOCR, PaddleOCR, RapidOCR, Surya. Use when extracting text from images, scanned documents, screenshots, or PDFs; building OCR pipelines; comparing engines. Triggers: OCR, text extraction, image to text, document scanning, Tesseract, EasyOCR, PaddleOCR.
---

# OCR Tools Skill

## When to Use

Use this skill when you need to:
- Extract text from images, screenshots, or scanned documents
- Build OCR pipelines with preprocessing
- Choose the right OCR engine for a task
- Handle PDFs that are actually images

## Core Principles

1. **Preprocessing is mandatory** — raw images rarely yield optimal results
2. **Match engine to use case** — no single engine wins on all dimensions
3. **Hybrid strategies work** — cascade multiple engines for difficult inputs
4. **Post-processing is not optional** — spellcheck and normalize output

## Engine Comparison

| Engine | Accuracy | Speed | Languages | Install Complexity | Best For |
|--------|----------|-------|-----------|-------------------|----------|
| **Tesseract** | Good | Fast | 100+ | Low (apt-get) | General purpose, offline |
| **EasyOCR** | Good | Medium | 80+ | Medium (pip) | Modern deep learning |
| **PaddleOCR** | Excellent | Medium | 80+ | Medium | CJK + production |
| **RapidOCR** | Good | Fast | 50+ | Low | Lightweight, no PyTorch |
| **Surya** | Excellent | Slow | 90+ | Medium | Document layout, tables |

### Tesseract (Free, Offline)

```bash
# WSL2/Linux
sudo apt-get install tesseract-ocr tesseract-ocr-eng

# Python
pip install pytesseract Pillow
```

```python
import pytesseract
from PIL import Image

image_path = 'path/to/image.png'
text = pytesseract.image_to_string(Image.open(image_path))
print(text)
```

### EasyOCR (Modern Alternative)

```bash
pip install easyocr
```

```python
import easyocr
reader = easyocr.Reader(['en', 'es'])
result = reader.readtext('path/to/image.png')
for (bbox, text, prob) in result:
    print(f'Text: {text}, Confidence: {prob:.2f}')
```

### PaddleOCR (Best for CJK + Production)

```bash
pip install paddleocr
```

```python
from paddleocr import PaddleOCR
ocr = PaddleOCR(use_angle_cls=True, lang='en')
result = ocr.ocr('image.png', cls=True)
for line in result[0]:
    print(f"{line[1][0]} (conf: {line[1][1]:.2f})")
```

### RapidOCR (Lightest Option)

```bash
pip install rapidocr onnxruntime
```

ONNX-based, zero PyTorch dependency. Multi-language bindings (Python/C++/Java/C#).

### Surya (Best for Documents)

```bash
pip install surya-ocr
```

Layout-aware OCR with table and LaTeX extraction. 90+ languages.

## Preprocessing Pipeline

Apply these steps sequentially before feeding images to any OCR engine:

```python
import cv2
import numpy as np

def preprocess_ocr(img):
    # 1. Grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # 2. Denoise
    denoised = cv2.medianBlur(gray, 3)
    # 3. CLAHE contrast enhancement
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    enhanced = clahe.apply(denoised)
    # 4. Binarization (Otsu for clean docs)
    _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    # 5. Deskew via Hough transform
    coords = np.column_stack(np.where(binary > 0))
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45: angle = 90 + angle
    h, w = binary.shape
    matrix = cv2.getRotationMatrix2D((w//2, h//2), angle, 1.0)
    deskewed = cv2.warpAffine(binary, matrix, (w, h), borderValue=255)
    return deskewed
```

**Pipeline order matters.** Each step enables the next.

## Hybrid Strategies

### Cascade Approach

Run multiple engines and combine results:

```python
def cascade_ocr(image_path):
    # Try fastest first
    rapid_result = rapidocr(image_path)
    if confidence(rapid_result) > 0.9:
        return rapid_result
    
    # Fall back to accurate
    surya_result = surya(image_path)
    return merge_results(rapid_result, surya_result)
```

### Region-Specific

Different engines for different image regions:

```python
def region_ocr(image):
    # Text regions → Tesseract
    text_regions = detect_text_regions(image)
    text = tesseract(image, text_regions)
    
    # Tables → Surya
    table_regions = detect_tables(image)
    tables = surya(image, table_regions)
    
    return {'text': text, 'tables': tables}
```

## Postprocessing

- **Spellcheck** with `symspellpy` or context-aware models
- **Regex normalization** for dates, numbers, whitespace
- **Domain dictionaries** for specialized terms (medical, legal, etc.)

## Anti-Patterns

- ❌ Feeding raw camera photos directly to OCR
- ❌ Using Tesseract for CJK text
- ❌ Ignoring confidence scores
- ❌ Running one engine and accepting its output as final
- ❌ Forgetting to deskew skewed images

## Quick Reference

```python
# Full pipeline example
from PIL import Image
import cv2
import easyocr

def ocr_pipeline(image_path):
    img = cv2.imread(image_path)
    processed = preprocess_ocr(img)
    reader = easyocr.Reader(['en'])
    result = reader.readtext(processed)
    return postprocess(result)
```

## References

See `references/engine-details.md` for detailed engine comparisons.
See `references/preprocessing.md` for the full preprocessing pipeline.