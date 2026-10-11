#!/bin/bash
# load-handover.sh - inject HANDOVER.md into the model prompt at session start.

set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')

if [ -z "$cwd" ]; then
  cwd="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-$PWD}}"
fi

handover="$cwd/HANDOVER.md"

if [ -f "$handover" ]; then
  content=$(cat "$handover")
  jq -n --arg ctx "$content" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
fi

exit 0
