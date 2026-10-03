#!/usr/bin/env bash
# read-limits.sh - print how much of the Claude 5-hour and weekly limits is used.
# Asks the usage endpoint Claude Code's `/usage` reads, with the OAuth token
# Claude Code keeps, so it works without an open Claude Code. When that fails
# (no token, expired token, endpoint changed) it falls back to the copy the
# statusline saves (configs/claude-powerline/record-rate-limits.sh).
# The token never leaves this script: it is not printed and not written.

set -uo pipefail

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/claude/rate-limits.json"
now=$(date +%s)

credentials() {
  if [ "$(uname)" = Darwin ]; then
    # Claude Code suffixes the keychain service with the first 8 hex digits of
    # sha256(CLAUDE_CONFIG_DIR) when that variable is set
    local service="Claude Code-credentials"
    if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
      service="$service-$(printf %s "$CLAUDE_CONFIG_DIR" | shasum -a 256 | cut -c1-8)"
    fi
    security find-generic-password -s "$service" -w 2>/dev/null && return
  fi
  cat "$config_dir/.credentials.json" 2>/dev/null
}

# usage endpoint -> the shape the statusline saves: used_percentage, resets_at
# in epoch seconds
from_api() {
  local token
  token=$(credentials | jq -er --argjson now "$now" \
    '.claudeAiOauth | select(.expiresAt / 1000 > $now) | .accessToken' 2>/dev/null) || return 1
  curl -fsS --max-time 10 https://api.anthropic.com/api/oauth/usage \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null |
    jq -ce --argjson now "$now" '
      def win: select(type == "object" and .utilization != null)
        | {used_percentage: .utilization,
           resets_at: (.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601)};
      {source: "api", updated_at: $now}
        + ({five_hour: (.five_hour | win)} // {})
        + ({seven_day: (.seven_day | win)} // {})
      | select(has("five_hour") or has("seven_day"))' 2>/dev/null
}

if ! limits=$(from_api); then
  if [ ! -s "$state" ]; then
    echo no-data
    exit 0
  fi
  limits=$(jq -c '{source: "statusline"} + .' "$state")
fi

jq -r --argjson now "$now" '
  def left($t): (($t - $now) / 60 | floor) as $m
    | if $m <= 0 then "already reset"
      elif $m >= 1440 then "resets in \($m / 1440 | floor)d \($m % 1440 / 60 | floor)h"
      else "resets in \($m / 60 | floor)h \($m % 60)m" end;
  if .source == "api" then "source: live (usage endpoint)"
  else "source: statusline copy, \(($now - .updated_at) / 60 | floor) min old (\(.updated_at | localtime | strftime("%m/%d %H:%M")))" end,
  (.five_hour // empty | "5-hour: \(.used_percentage | round)% (\(left(.resets_at)))"),
  (.seven_day // empty | "weekly: \(.used_percentage | round)% (\(left(.resets_at)))")' <<<"$limits"
