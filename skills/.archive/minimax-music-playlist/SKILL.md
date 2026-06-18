---
name: minimax-music-playlist
description: Scan the user's music taste, build a taste profile, generate a personalized playlist, and create an album cover via MiniMax API.
tags: [music, playlist, ai, minimax]
---

# MiniMax Music Playlist — Personalized Playlist Generator


## When to Use
- Create and manage music playlists
- Organize generated music by mood or genre
- Curate audio collections
- Manage music metadata

## Do Not Use
- Generate new music (use minimax-music-gen)
- Audio editing or processing
- Document or file management

## Prerequisites
- **mmx CLI**: `npm install -g mmx-cli` → `mmx auth login --api-key <key>`
- **Audio player**: `mpv`, `ffplay`, or `afplay` (macOS)

## Language
All user-facing text in user's detected language. `mmx` prompts in English. Lyrics language follows genre (K-pop→Korean, J-pop→Japanese, etc.).

## Workflow
```
1. Scan local music apps → 2. Build taste profile → 3. Plan playlist
→ 4. Generate songs (mmx music) → 5. Generate cover (mmx image) → 6. Play → 7. Save & feedback
```

## Step 1: Gather Music Data
| Source | Method |
|--------|--------|
| Apple Music | `osascript` to query Music.app |
| Spotify | User exports via Spotify Privacy Settings (JSON files in ZIP) |
| Manual | User describes their taste directly |

## Step 2: Build Taste Profile
Analyze gathered data for: genre distribution, artist frequency, tempo/BPM range, mood patterns, language distribution, era preferences. Output like:
```
Top genres: indie rock (42%), electronic (28%),...
Top artists: Glass Animals, Tame Impala,...
Mood: balanced between energetic and chill
Preferred language: English (70%), Korean (20%)
Listening era: mostly current (2020-2025)
```

## Step 3: Plan Playlist
Generate 5-7 song plan with variety. Each song gets: theme/concept, genre, mood, BPM, vocal, language, lyrics theme.
Ensure genre variety across playlist (no more than 2 songs same genre).
Title: pick a theme or concept that ties the playlist together.

## Step 4: Generate Songs
For each song: `mmx music generate --prompt "<prompt>" --lyrics "<lyrics>" --out song-N.mp3`
Lyrics follow genre conventions. Each song lyrics use song's language.

## Step 5: Generate Album Cover
```bash
mmx image generate --prompt "Album cover for <title>: <description>" --aspect-ratio 1:1 --n 1 --out cover.png
```

## Step 6: Play & Save
Play with `mpv <file>`. Save to `~/.claude/skills/minimax-music-playlist/playlists/<name>/`.
Save info: playlist name, date, song list, cover art path, taste profile summary.

## Step 7: Feedback
Ask: "Did you like this playlist? (y/N)" → Adjust next generation accordingly.
Save feedback to memory for future personalization.

## Verification
- [ ] Music listening data collected from at least one source
- [ ] Taste profile generated with genre/artist/mood distribution
- [ ] Playlist planned with 5-7 songs (varied genres)
- [ ] All songs generated without errors
- [ ] Album cover generated
- [ ] Playlist saved to disk
