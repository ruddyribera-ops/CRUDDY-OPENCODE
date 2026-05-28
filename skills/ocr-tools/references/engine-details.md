# OCR Engine Details

## Tesseract OCR (Free, Offline)

### Installation (WSL2/Linux)
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr
sudo apt-get install tesseract-ocr-eng
# Install other language packs as needed, e.g., tesseract-ocr-spa for Spanish
```

### Python Snippet (using pytesseract)
```bash
pip install pytesseract Pillow
```

```python
import pytesseract
from PIL import Image

# Point to your tesseract executable if not in PATH
# pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

image_path = 'path/to/your/image.png'
text = pytesseract.image_to_string(Image.open(image_path))
print(text)
```

### Bash One-Liner
```bash
tesseract path/to/your/image.png output_text_file
cat output_text_file.txt
```

## EasyOCR (Alternative)

Modern deep-learning-based OCR with 80+ languages.

### Installation
```bash
pip install easyocr
```

### Python Snippet
```python
import easyocr

reader = easyocr.Reader(['en'])  # Specify languages, e.g., ['en', 'es']
result = reader.readtext('path/to/your/image.png')

for (bbox, text, prob) in result:
    print(f'Text: {text}, Confidence: {prob:.2f}')
```

## PaddleOCR (Best for CJK + Production)

PP-OCRv5 — 0.10 CER, 12.7 FPS GPU. Includes layout analysis via PP-StructureV3.

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

## RapidOCR (Lightest Windows Option)

ONNX-based, multi-language bindings (Python/C++/Java/C#). Zero PyTorch dependency.

```bash
pip install rapidocr onnxruntime
```

## Surya (Best for Documents)

Layout-aware OCR with table/LaTeX extraction. 90+ languages.

```bash
pip install surya-ocr
```
