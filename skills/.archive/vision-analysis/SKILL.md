---
name: vision-analysis
description: Computer vision and image analysis — object detection, classification, recognition, and image processing pipelines.
tags: [vision, ai, image, analysis, computer-vision]
---

# Vision Analysis

## When to Use
- Analyze images or video content programmatically
- Implement computer vision pipelines
- Object detection, classification, or recognition tasks
- Image processing and analysis

## Do Not Use
- OCR text extraction from images (use ocr-tools)
- General image generation (use mmx-cli)
- UI screenshot testing (use playwright or adaptive-ui)
- Audio or text analysis

Analyze images using the MiniMax `MiniMax_understand_image` MCP tool.

## Prerequisites
- MiniMax Token Plan subscription with valid `MINIMAX_API_KEY`
- MiniMax MCP configured (`MiniMax_understand_image` tool available)

See `references/setup.md` for per-environment MCP configuration steps.

## Analysis Modes

| Mode | When to use | Prompt strategy |
|------|-------------|-----------------|
| `describe` | General image understanding | Ask for detailed description |
| `ocr` | Text extraction from screenshots, documents | Ask to extract all text verbatim |
| `ui-review` | UI mockups, wireframes, design files | Ask for design critique with suggestions |
| `chart-data` | Charts, graphs, data visualizations | Ask to extract data points and trends |
| `object-detect` | Identify objects, people, activities | Ask to list and locate all elements |

See `references/prompts.md` for exact prompts and output formats per mode.

## Workflow

### Step 1: Auto-detect image
Triggered automatically when message contains image file extensions: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.bmp`, `.svg`

### Step 2: Select analysis mode and call MCP tool
Use `MiniMax_understand_image` tool with a mode-specific prompt.

### Step 3: Present results
Return analysis clearly — readable prose for describe, preserved structure for OCR, structured critique for ui-review.

## Notes
- Images up to 20MB supported (JPEG, PNG, GIF, WebP)
- Local file paths work if MiniMax MCP is configured with file access
- The `MiniMax_understand_image` tool is provided by `minimax-coding-plan-mcp`

## Verification
- [ ] MCP tool responds without errors
- [ ] Analysis matches the selected mode's intent
- [ ] OCR output preserves original text structure
- [ ] UI review includes strengths, issues, and suggestions
- [ ] Chart data extraction captures all readable data points
- [ ] Result presented clearly to user

## See Also
- `references/ecosystem.md` — full CV library listing
- `ocr-tools` skill for dedicated OCR pipelines
