# Preprocessing Pipeline

Order matters. Apply these steps sequentially before feeding images to any OCR engine.

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

## Postprocessing
- Spellcheck with `symspellpy` or context-aware models
- Regex normalization for dates, numbers, whitespace
- Custom domain dictionaries for specialized terms
