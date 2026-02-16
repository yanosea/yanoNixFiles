#!/bin/bash
set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')

if [ -z "$cwd" ]; then
  cwd="${CLAUDE_PROJECT_DIR:-.}"
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
