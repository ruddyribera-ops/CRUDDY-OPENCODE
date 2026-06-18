---
name: gif-sticker-maker
description: Create animated GIFs and stickers from video clips and image sequences with optimization.
tags: [creative, gif, image, media]
---

# GIF Sticker Maker

## When to Use
- Create animated GIFs from video or image sequences
- Generate stickers for messaging apps
- Convert video clips to animated stickers
- Optimize GIF size and quality

## Do Not Use
- Video editing or post-production
- Static image creation
- Audio processing
- Complex animation (use dedicated animation tools)

Convert user photos into 4 animated GIF stickers (Funko Pop / Pop Mart style).

## Style Spec
- Funko Pop / Pop Mart blind box 3D figurine
- C4D / Octane rendering quality
- White background, soft studio lighting
- Caption: black text + white outline, bottom of image

## Prerequisites
1. **Python venv** activated with dependencies from `references/requirements.txt`
2. **`MINIMAX_API_KEY`** exported
3. **`ffmpeg`** available on PATH

## Workflow

### Step 0: Collect Captions
Ask user for custom captions or use defaults from `references/captions.md`.

### Step 1: Generate 4 Static Sticker Images
Use `scripts/minimax_image.py` — one per action (hi, laugh, cry, love). Pass `--subject-ref <photo>` for person subjects. Run all 4 concurrently.

See `references/commands.md` for full invocation details.

### Step 2: Animate Each Image → Video
Use `scripts/minimax_video.py` with `--image` flag. Run all 4 concurrently.

### Step 3: Convert Videos → GIF
Use `scripts/convert_mp4_to_gif.py` on all 4 MP4s.

### Step 4: Deliver
Output `<deliver_assets>` block with all 4 GIFs — no text after.

## Default Actions

| # | Action | Filename ID | Animation |
|---|--------|-------------|-----------|
| 1 | Happy waving | hi | Wave hand, slight head tilt |
| 2 | Laughing hard | laugh | Shake with laughter, eyes squint |
| 3 | Crying tears | cry | Tears stream, body trembles |
| 4 | Heart gesture | love | Heart hands, eyes sparkle |

See `references/captions.md` for multilingual caption defaults.

## Rules
- Detect user's language, all outputs follow it
- Captions MUST come from `references/captions.md` matching user's language column — never mix languages
- All image prompts must be in **English** regardless of user language (only caption text is localized)
- `<deliver_assets>` must be LAST in response, no text after
- All 4 generations in Steps 1 & 2 are independent — run concurrently

## Verification
- [ ] All 4 stickers generated as GIF files
- [ ] Captions match user's language
- [ ] Subject reference applied correctly for person photos
- [ ] `<deliver_assets>` block is the last output
