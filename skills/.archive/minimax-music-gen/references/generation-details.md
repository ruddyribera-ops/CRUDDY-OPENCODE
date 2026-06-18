# Music Generation — Detailed Workflow

## CLI Commands

### Vocal with auto-generated lyrics
```bash
mmx music generate --prompt "<prompt>" --lyrics-optimizer \
  --genre "<genre>" --mood "<mood>" --vocals "<vocal>" \
  --instruments "<instruments>" --bpm <bpm> \
  --out ~/Music/minimax-gen/<file>.mp3 --quiet --non-interactive
```

### Vocal with user lyrics
```bash
mmx music generate --prompt "<prompt>" --lyrics "<lyrics with markers>" \
  --genre "<genre>" --mood "<mood>" --vocals "<vocal>" \
  --out ~/Music/minimax-gen/<file>.mp3 --quiet --non-interactive
```

### Instrumental
```bash
mmx music generate --prompt "<prompt>" --instrumental \
  --genre "<genre>" --mood "<mood>" --instruments "<instruments>" \
  --out ~/Music/minimax-gen/<file>.mp3 --quiet --non-interactive
```

### Cover from file
```bash
mmx music cover --prompt "<cover style>" --audio-file <source.mp3> --out ~/Music/minimax-gen/<file>.mp3
```

### Cover from URL
```bash
mmx music cover --prompt "<cover style>" --audio <url> --out ~/Music/minimax-gen/<file>.mp3
```

### Cover with custom lyrics
```bash
mmx music cover --prompt "<style>" --audio-file <source.mp3> --lyrics "<custom lyrics>" --out out.mp3
```

## Basic Mode Details
1. Expand user's one-liner into rich prompt: `A [mood] [BPM] [genre] song, featuring [vocal], about [theme], [atmosphere], [instruments].`
2. Show user preview (localized, not raw English prompt)
3. On confirm, call mmx

## Advanced Control Mode Details
1. **Lyrics phase**: Display/edit lyrics with section markers. Use `--lyrics-optimizer` for auto-gen.
2. **Prompt phase**: Generate recommended prompt as editable tags
3. **Planning**: Structure, BPM, references, vocal character
4. **Confirmation**: Show all params, then generate

## Cover Mode Details
1. Ask for source audio (local file or URL, mp3/wav/flac, 6s-6min, max 50MB)
2. Ask for target cover style
3. Optionally custom lyrics
4. Optional flags: `--seed`, `--channel`, `--format`, `--sample-rate`, `--bitrate`

## Playback
Detect player priority: `mpv` > `ffplay` > `afplay`. Show file path if none found.

## Error Handling
| Error | Action |
|-------|--------|
| mmx not found | `npm install -g mmx-cli` |
| Auth error (exit 3) | `mmx auth login` |
| Quota exceeded (exit 4) | Report limit, suggest waiting |
| Timeout (exit 5) | Retry once |
| Content filter (exit 10) | Adjust prompt |
| No audio player | Save & show path, suggest mpv |

## Important Notes
- Never reproduce copyrighted lyrics (write original for covers)
- API prompt works best in English
- Section markers: `[verse]`, `[chorus]`, `[bridge]`, `[outro]`, `[intro]`
- Prefer structured flags (`--genre`, `--mood`, `--vocals`) over cramming in `--prompt`
- Clean up `~/Music/minimax-gen/` if > 50 files
