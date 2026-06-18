## Agent Mail System — Persistent Inter-Agent Communication
**Inspired by GasTown nudge/mail.** Agents can leave persistent messages for each other.
Messages survive session restarts. All agents check their mailbox at task start.

### Commands

```powershell
python $CONFIG/scripts/mail.py send <agent> --subject "Subject" --body "Message"
python $CONFIG/scripts/mail.py inbox [<agent>]          # Check inbox
python $CONFIG/scripts/mail.py read <msg-id>             # Read + mark read
python $CONFIG/scripts/mail.py clear [<agent>]           # Clear mailbox
```

### Protocol

- **When starting a task:** Check inbox. Process unread messages before starting new work.
- **When completing a task:** If you noticed something another agent should handle, send them a mail instead of silently ignoring it.
- **When stuck:** Send mail to `@main-coordinator` with what you found and what you need.
- **Mail is persistent** — survives crashes, restarts, and context resets.
- **Mail is NOT real-time** — the recipient reads it on their next task start.

### Examples

```powershell
# code-builder notices a security smell
python $CONFIG/scripts/mail.py send code-analyzer -s "Auth middleware in routes/auth.ts" -b "Rate limiting missing. Should review."

# bug-fixer finds an architectural issue
python $CONFIG/scripts/mail.py send architecture-advisor -s "DB connection pooling" -b "Every request opens a new connection. Consider a pool."

# specialist is blocked
python $CONFIG/scripts/mail.py send main-coordinator -s "BLOCKED on API key" -b "Need GROQ_API_KEY to test the integration. User hasn't provided it."
```

