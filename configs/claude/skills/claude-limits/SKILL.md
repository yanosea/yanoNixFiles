---
name: claude-limits
description: Check how much of the Claude 5-hour and weekly usage limits is used. Use when asked about remaining usage or limits, before starting heavy or long-running work, and before a periodic check-in.
---

# Read the Claude usage limits

## 1. Read

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/claude-limits/read-limits.sh"
```

Run it silently. It prints three lines: the source, the 5-hour window and the weekly window. `no-data` means neither source worked.

- `source: live` comes from the usage endpoint Claude Code's `/usage` reads, with the OAuth token Claude Code keeps (keychain on macOS, `.credentials.json` elsewhere). It needs no open Claude Code session.
- `source: statusline copy, N min old` is the fallback: what the statusline last saved. It only grows while a Claude Code session is drawing its statusline, so the real value is at least this much. Past an hour old, say "as of <time>".
- `already reset` means that window started over from 0%.
- `no-data`: say the limits cannot be read right now. Never guess a number.

The endpoint is undocumented. If the output keeps falling back while a token exists, the endpoint has probably changed: say so instead of trusting the stale copy.

## 2. Say it

- 80% or more in either window: bring it up unprompted, with the value and roughly when it resets.
- 50% or more: mention it when asked, or before starting heavy work.
- Below that, stay quiet unless asked.
- Use human-scale times ("in about 2 hours", "back on Monday morning"), never seconds or epoch values.
- Whether to cut back or postpone work is the user's call: report, do not stop on your own.
