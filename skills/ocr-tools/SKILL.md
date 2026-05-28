---
name: ocr-tools
description: OCR (Optical Character Recognition) tools and patterns — Tesseract, EasyOCR, PaddleOCR, RapidOCR, Surya, docTR. Covers installation (Windows/Linux/macOS), preprocessing pipelines, hybrid strategies, postprocessing, and document analysis. Use when extracting text from images, scanned documents, screenshots, or PDFs; building OCR pipelines; or comparing OCR engines for your use case.
tags: [ocr, document, python, extraction]
---

# OCR Tools (Optical Character Recognition)

## When to Use
- Extract text from scanned documents or images
- Build OCR pipelines for document digitization
- Compare OCR engines (Tesseract, EasyOCR, PaddleOCR)
- Process batch document scans

## Do Not Use
- PDF creation or editing (use minimax-pdf)
- Document format conversion to DOCX/XLSX
- Image processing or enhancement
- Handwriting recognition (limited support)

## Engine Comparison

| Engine | Best For | Speed | Accuracy |
|--------|----------|-------|----------|
| **Tesseract** | Free, offline, 100+ languages | Medium | Good (clean docs) |
| **EasyOCR** | Modern DL, 80+ languages | Medium | Very good |
| **PaddleOCR** | CJK + production, 0.10 CER | 12.7 FPS GPU | Excellent |
| **RapidOCR** | Windows, no PyTorch dep | Fast | Good |
| **Surya** | Layout-aware documents, 90+ langs | Slow | Excellent |

See `references/engine-details.md` for per-engine installation, Python snippets, and CLI commands.

## Hybrid Strategy (Best Accuracy)
Use **PaddleOCR for bulk** (12.7 FPS) → fallback to **EasyOCR** for low-confidence (< 0.7). Achieves ~0.08 CER at 9.4 FPS avg.

## Preprocessing
Apply these steps in order before OCR:
1. Grayscale conversion
2. Denoise (median blur)
3. CLAHE contrast enhancement
4. Binarization (Otsu)
5. Deskew (Hough transform)

See `references/preprocessing.md` for full Python implementation.

## Windows-Specific Notes
```powershell
# Tesseract via winget
winget install UB-Mannheim.TesseractOCR

# Set path in Python
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# RapidOCR uses ONNX — no PyTorch needed
pip install rapidocr onnxruntime
```

## Verification
- [ ] Text extracted from test image matches expected content
- [ ] Preprocessing pipeline runs without errors
- [ ] Chosen engine supports the language(s) needed
- [ ] File size/format constraints met

## Key Resources
- [Awesome OCR](https://github.com/kba/awesome-ocr)
- [Tesseract docs](https://tesseract-ocr.github.io/tessdoc/)
- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR)
- [EasyOCR](https://github.com/JaidedAI/EasyOCR)
- [OCRmyPDF](https://github.com/ocrmypdf/OCRmyPDF) — searchable PDF from scans
