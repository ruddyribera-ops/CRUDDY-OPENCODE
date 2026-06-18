---
name: mmx-cli
description: Use mmx to generate text, images, video, speech, and music via the MiniMax AI platform. Chat, web search, and API resource management from the terminal.
tags: [minimax, ai, media, cli]
---

## When to Use

- Generating text, images, video, speech, or music via the MiniMax AI platform
- Chatting with MiniMax language models from the terminal
- Performing web search through the MiniMax API
- Managing MiniMax API keys and account resources

## Do Not Use
- PDF generation (use minimax-pdf)
- Excel spreadsheets (use minimax-xlsx)
- PowerPoint editing (use ppt-editing-skill)

# MiniMax CLI — Agent Skill Guide

## Prerequisites
```bash
npm install -g mmx-cli
mmx auth login --api-key sk-xxxxx
```
Region auto-detected. Override: `--region global` or `--region cn`. Config at `~/.mmx/credentials.json`.

## Quick Reference

| Task | Command |
|------|---------|
| Text chat | `mmx text chat --message <text> [--system "prompt"]` |
| Image gen | `mmx image generate --prompt <text> [--aspect-ratio 16:9] [--n 3]` |
| Video gen | `mmx video generate --prompt <text> [--download out.mp4]` |
| Speech TTS | `mmx speech synthesize --text <text> [--voice <id>] --out audio.mp3` |
| Music gen | `mmx music generate --prompt <text> --lyrics <text> --out song.mp3` |
| Vision | `mmx vision describe --image photo.jpg [--prompt "What is this?"]` |
| Web search | `mmx search query --q "query"` |
| Quota | `mmx quota show` |

→ See `references/commands.md` for all flags, exit codes, piping patterns, and configuration.

## Agent Flags (Always in CI/Agent)
`--non-interactive --quiet --output json [--async for video]`

## Full Command Reference
→ `references/commands.md` contains:
- Complete flag tables for each command (text chat, image, video, speech, music, vision, search, quota)
- Tool schema export (`mmx config export-schema`)
- Exit codes reference
- Piping patterns and CI workflows
- Configuration precedence and environment variables

## Verification
- [ ] `mmx auth login` succeeds
- [ ] `mmx text chat --message "Hi" --output json --quiet` returns valid JSON
- [ ] `mmx quota show` displays remaining quota
- [ ] Generated files exist at specified output paths
- [ ] All reference links resolve
