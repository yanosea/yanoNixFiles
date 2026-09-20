#!/usr/bin/env bash
# inject-context.sh - pass HANDOVER.md and plugin triage to the model once per
# session; PostToolUse is the only grok event whose output reaches the model.

set -uo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.sessionId // .session_id // empty')
cwd=$(echo "$input" | jq -r '.workspaceRoot // .cwd // empty')
[ -z "$cwd" ] && cwd="${GROK_WORKSPACE_ROOT:-$PWD}"
[ -z "$session_id" ] && session_id="${GROK_SESSION_ID:-}"
[ -z "$session_id" ] && exit 0

STATE_DIR="${HOME}/.cache/grok-hook-state"
mkdir -p "$STATE_DIR"

marker="${STATE_DIR}/${session_id}"
[ -e "$marker" ] && exit 0
touch "$marker"
find "$STATE_DIR" -type f -mtime +7 -delete 2>/dev/null

sections=()
if [ -f "$cwd/HANDOVER.md" ]; then
  sections+=("$(cat "$cwd/HANDOVER.md")")
fi
plugins=$(bash "$(dirname "$0")/check-new-plugins.sh" 2>/dev/null)
[ -n "$plugins" ] && sections+=("$plugins")

[ ${#sections[@]} -eq 0 ] && exit 0

ctx=$(printf '%s\n\n' "${sections[@]}")
jq -n --arg ctx "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'

exit 0
