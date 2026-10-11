#!/bin/bash
# remind-websearch.sh - inject a reminder to verify time-sensitive information.

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
