#!/bin/bash
# load-handover.sh - inject HANDOVER.md into the model prompt at session start.
# Codex counterpart of configs/claude/hooks/load-handover.sh; the payload and
# the additionalContext output shape are identical between the two tools.

set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')

# codex sets no env vars for hooks, so the working directory is the only fallback
if [ -z "$cwd" ]; then
  cwd="$PWD"
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
