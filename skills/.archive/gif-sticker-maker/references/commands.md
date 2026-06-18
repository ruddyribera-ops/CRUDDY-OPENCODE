# Commands & Tool Details

## Step 1: Generate 4 Static Sticker Images

**Tool**: `scripts/minimax_image.py`

```bash
python3 scripts/minimax_image.py "<prompt>" -o output/sticker_hi.png --ratio 1:1 --subject-ref <photo>
python3 scripts/minimax_image.py "<prompt>" -o output/sticker_laugh.png --ratio 1:1 --subject-ref <photo>
python3 scripts/minimax_image.py "<prompt>" -o output/sticker_cry.png --ratio 1:1 --subject-ref <photo>
python3 scripts/minimax_image.py "<prompt>" -o output/sticker_love.png --ratio 1:1 --subject-ref <photo>
```

> `--subject-ref` only works for person subjects (API limitation: type=character). For animals/objects/logos, omit the flag and rely on text description.

## Step 2: Animate Each Image → Video

**Tool**: `scripts/minimax_video.py` with `--image` flag (image-to-video mode)

```bash
python3 scripts/minimax_video.py "<prompt>" --image output/sticker_hi.png -o output/sticker_hi.mp4
python3 scripts/minimax_video.py "<prompt>" --image output/sticker_laugh.png -o output/sticker_laugh.mp4
python3 scripts/minimax_video.py "<prompt>" --image output/sticker_cry.png -o output/sticker_cry.mp4
python3 scripts/minimax_video.py "<prompt>" --image output/sticker_love.png -o output/sticker_love.mp4
```

All 4 calls are independent — run concurrently.

## Step 3: Convert Videos → GIF

**Tool**: `scripts/convert_mp4_to_gif.py`

```bash
python3 scripts/convert_mp4_to_gif.py output/sticker_hi.mp4 output/sticker_laugh.mp4 output/sticker_cry.mp4 output/sticker_love.mp4
```

Outputs GIF files alongside each MP4 (e.g. `sticker_hi.gif`).

## Tools & Workflows

### Command-Line Tools
- **FFmpeg** — video/GIF encoding, trimming, scaling, filter graphs
- **gifski** — high-quality GIF encoder (perceptual palette)
- **gifsicle** — GIF optimization, frame reduction, transparency
- **apng-canvas** — APNG encoder (better quality than GIF)
- **ImageMagick** — image resize, compose, convert formats

### Python Libraries
- **imageio** — read/write GIF/MP4, frame-by-frame manipulation
- **moviepy** — video editing, GIF export, ffmpeg wrapper
- **Pillow** — GIF frame extraction, resize, text overlay
- **pygifsicle** — Python wrapper for gifsicle optimization

### Optimization Strategies
- `gifsicle -O3` — highest optimization level
- Palette generation — limit colors to 256, use perceptual palette
- Frame reduction — drop every other frame, target 10-15 fps
- Dithering — Floyd-Steinberg for smooth color transitions

### Watermark Overlay
```bash
# FFmpeg drawtext watermark
ffmpeg -i input.mp4 -vf "drawtext=text='@brand':fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:x=W-w-10:y=H-h-10" output.mp4

# ImageMagick composite overlay
magick composite -gravity southeast -geometry +10+10 watermark.png input.gif output.gif
```

## Deliver Format

Output format (strict order):
1. Brief status line (e.g. "4 stickers created:")
2. `<deliver_assets>` block with all GIF files
3. **NO text after deliver_assets**

```xml
<deliver_assets>
<item><path>output/sticker_hi.gif</path></item>
<item><path>output/sticker_laugh.gif</path></item>
<item><path>output/sticker_cry.gif</path></item>
<item><path>output/sticker_love.gif</path></item>
</deliver_assets>
```
