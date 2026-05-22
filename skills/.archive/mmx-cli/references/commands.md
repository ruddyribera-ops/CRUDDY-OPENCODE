# mmx CLI — Complete Command Reference

## Configuration Precedence
CLI flags → environment variables → `~/.mmx/config.json` → defaults.

## Agent Flags (Always in CI/Agent)
`--non-interactive`, `--quiet`, `--output json`, `--async`, `--dry-run`, `--yes`

## text chat
```bash
mmx text chat --message <text> [flags]
```
Flags: `--message` (required, repeatable, prefix with `role:`), `--messages-file`, `--system`, `--model` (default: MiniMax-M2.7), `--max-tokens`, `--temperature`, `--top-p`, `--stream`, `--tool`

## image generate
```bash
mmx image generate --prompt <text> [flags]
```
Flags: `--prompt` (required), `--aspect-ratio` (e.g., 16:9, 1:1), `--n` (count), `--subject-ref`, `--out-dir`, `--out-prefix`

## video generate
```bash
mmx video generate --prompt <text> [flags]
```
Flags: `--prompt` (required), `--model` (Hailuo-2.3), `--first-frame`, `--callback-url`, `--download`, `--async`, `--no-wait`, `--poll-interval`
Commands: `mmx video task get --task-id <id>`, `mmx video download --file-id <id>`

## speech synthesize
```bash
mmx speech synthesize --text <text> [flags]
```
Flags: `--text`/`--text-file`, `--model` (speech-2.8-hd), `--voice`, `--speed`, `--volume`, `--pitch`, `--format`, `--sample-rate`, `--bitrate`, `--channels`, `--language`, `--subtitles`, `--pronunciation`, `--sound-effect`, `--out`, `--stream`

## music generate
```bash
mmx music generate --prompt <text> [--lyrics <text>] [flags]
```
Flags: `--prompt`, `--lyrics`/`--lyrics-file`, `--vocals`, `--genre`, `--mood`, `--instruments`, `--tempo`, `--bpm`, `--key`, `--avoid`, `--use-case`, `--structure`, `--references`, `--extra`, `--instrumental`, `--aigc-watermark`, `--format`, `--sample-rate`, `--bitrate`, `--out`, `--stream`
At least one of `--prompt` or `--lyrics` required. Cannot use `--instrumental` with `--lyrics`.

## vision describe
```bash
mmx vision describe (--image <path-or-url> | --file-id <id>) [flags]
```
Flags: `--image`/`--file-id`, `--prompt` (default: "Describe the image.")

## search query
```bash
mmx search query --q <query>
```

## quota show
```bash
mmx quota show [--output json]
```

## Tool Schema Export
```bash
mmx config export-schema [--command "video generate"]
```

## Exit Codes
0=Success, 1=General error, 2=Usage error, 3=Auth error, 4=Quota exceeded, 5=Timeout, 10=Content filter

## Piping Patterns
```bash
mmx text chat --message "Hi" --output json | jq '.content'
mmx video generate --prompt "Waves" 2>/dev/null
URL=$(mmx image generate --prompt "A sunset" --quiet)
mmx vision describe --image "$URL" --quiet
TASK=$(mmx video generate --prompt "A robot" --async --quiet | jq -r '.taskId')
mmx video task get --task-id "$TASK" --output json
```

## MiniMax Ecosystem
- Models: text (MiniMax-M2.7), image (image-01), video (Hailuo-2.3), audio (speech-2.8-hd), music (music-2.5)
- Check quotas: `mmx quota show`
- Config: `mmx config set --key region --value cn`
- Environment: `MINIMAX_API_KEY`, `MINIMAX_REGION`
