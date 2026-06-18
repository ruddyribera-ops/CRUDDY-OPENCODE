---
name: minimax-music-gen
description: Generate songs (vocal or instrumental) using the MiniMax Music API. Supports Basic (one-sentence-in, song-out) and Advanced Control modes.
tags: [music, ai, minimax, creative]
---

# MiniMax Music Generation Skill


## When to Use
- Generate music tracks using AI
- Create background music for videos or presentations
- Generate instrumentals or melodies
- Explore AI music composition

## Do Not Use
- Generate singing vocals (use buddy-sings)
- Audio editing or mixing
- Music playlist management (use minimax-music-playlist)
- Professional music production

## Prerequisites
- **mmx CLI**: `npm install -g mmx-cli` → `mmx auth login --api-key <key>` → `mmx quota show`
- **Audio player**: `mpv` (preferred), `ffplay`, or `afplay` (macOS)

## Language
All user-facing text in user's detected language. API prompts in English for best quality.
Lyrics default to user's language, change only if explicitly requested.

## Quick Reference


## When to Use
- Generate music tracks using AI
- Create background music for videos or presentations
- Generate instrumentals or melodies
- Explore AI music composition

## Do Not Use
- Generate singing vocals (use buddy-sings)
- Audio editing or mixing
- Music playlist management (use minimax-music-playlist)
- Professional music production

| Mode | Command |
|------|---------|
| Vocal, auto-lyrics | `mmx music generate --prompt "..." --lyrics-optimizer --genre ... --mood ...` |
| Vocal, user lyrics | `mmx music generate --prompt "..." --lyrics "..." --genre ...` |
| Instrumental | `mmx music generate --prompt "..." --instrumental --genre ...` |
| Cover from file | `mmx music cover --prompt "style" --audio-file source.mp3` |
| Cover from URL | `mmx music cover --prompt "style" --audio <url>` |

**Agent flags**: always add `--quiet --non-interactive`

## Modes


## When to Use
- Generate music tracks using AI
- Create background music for videos or presentations
- Generate instrumentals or melodies
- Explore AI music composition

## Do Not Use
- Generate singing vocals (use buddy-sings)
- Audio editing or mixing
- Music playlist management (use minimax-music-playlist)
- Professional music production

**Basic Mode**: User gives one-liner → expand to rich prompt → show preview → generate
**Advanced Control**: Edit lyrics, refine prompt tags, plan structure/BPM/vocals
**Cover Mode**: Reference audio + style description → cover version

## Prompt Template
```
A [mood] [BPM] [genre] song, featuring [vocal description],
about [narrative/theme], [atmosphere], [key instruments and production].
```

## Full Workflow Details
→ See `references/generation-details.md` for:
- Complete CLI commands for all modes
- Basic, Advanced, and Cover mode step-by-step
- Playback detection and commands
- Error handling table
- Important notes (copyright, lyrics markers, structured params)

## Prompt Writing Guide
→ See `references/prompt_guide.md` for genre/vocal/instrument references and BPM tables.

## Storage
Generated music saved to `~/Music/minimax-gen/YYYYMMDD_HHMMSS_<slug>.mp3`.

## Feedback Loop
After playback: "How was this song?" → Love it, Adjust, Fine-tune, or Start over.

## Verification
- [ ] mmx CLI installed and authenticated (`mmx quota show` succeeds)
- [ ] Music file generated at `~/Music/minimax-gen/` path
- [ ] Audio player detected (or file path shown)
- [ ] User confirmed satisfaction or changes requested
- [ ] File cleaned up if user rejected
- [ ] All reference links resolve
