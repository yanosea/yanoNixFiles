#!/bin/bash
# remind-websearch.sh - counterpart of the inline UserPromptSubmit hook in
# configs/claude/settings.json. A script rather than an inline echo because
# codex only guarantees the JSON output shape, not bare stdout, on this event.

set -euo pipefail

# drain the payload; nothing in it is needed
cat >/dev/null

jq -n --arg ctx 'IMPORTANT: if this task touches library/API versions, tool behavior, pricing, or best practices that may have changed since training, you MUST search the web before answering. Do not rely on training-data memory for anything time-sensitive; skipping this when it applies is a mistake.' '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'

exit 0
