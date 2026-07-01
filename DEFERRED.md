# Deferred Audit Items

## L-2: Hardcoded Windows paths in plugin configs
**Status:** Deferred — high risk vs. low value
**Why deferred:**
- 11 plugins reference `C:\Users\Windows\.config\opencode\` directly
- Changing to env vars or relative paths touches opencode.json + plugin code
- Works fine for current single-user Windows setup
- Low ROI vs. risk of breaking runtime plugin loading

**Recommended action:** Revisit if/when you migrate to a different machine or share the config.
