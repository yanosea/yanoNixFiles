#!/usr/bin/env bash
# record-rate-limits.sh - Claude Code statusline: save the rate_limits of the
# payload where other tools can read them (the openclaw agents check them before
# heavy work), then hand the payload unchanged to claude-powerline.

set -uo pipefail

input=$(cat)
out="${XDG_STATE_HOME:-$HOME/.local/state}/claude/rate-limits.json"

# a payload without rate_limits (before the first response of a session) keeps
# the last known values; resets_at stays in epoch seconds as Claude Code sends it
if limits=$(jq -ce --argjson now "$(date +%s)" \
  '.rate_limits | select(type == "object" and length > 0) | {updated_at: $now} + .' \
  <<<"$input" 2>/dev/null); then
  # write and rename, so a reader never sees a half-written file
  if mkdir -p "${out%/*}" && tmp=$(mktemp "$out.XXXXXX"); then
    if ! { printf '%s\n' "$limits" >"$tmp" && mv -f "$tmp" "$out"; }; then
      rm -f "$tmp"
    fi
  fi
fi

exec claude-powerline <<<"$input"
