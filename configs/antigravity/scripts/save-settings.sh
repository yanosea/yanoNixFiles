#!/usr/bin/env bash
# save-settings.sh - write agy's settings.json back into the repo, minus the
# machine-local trustedWorkspaces. Run from the claude SessionStart hook: agy
# has no session-end event.

set -uo pipefail

LIVE="${HOME}/.gemini/antigravity-cli/settings.json"
REPO="$(ghq root 2>/dev/null || echo "$HOME/ghq")/github.com/yanosea/yanoNixFiles"
DEST="$REPO/configs/antigravity/settings.json"

[ -f "$LIVE" ] || exit 0
[ -f "$DEST" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# the repo is ahead and not applied yet
[ "$DEST" -nt "$LIVE" ] && exit 0

new=$(jq 'del(.trustedWorkspaces)' "$LIVE" 2>/dev/null) || exit 0
# compared by value: the repo copy is laid out by the formatter
[ "$(echo "$new" | jq -S .)" = "$(jq -S . "$DEST" 2>/dev/null)" ] && exit 0

echo "$new" >"$DEST"
