#!/usr/bin/env bash
# sync-mcp-servers.sh - Ensure the user-scope MCP servers declared in
# configs/claude/mcp-servers.conf are registered (SessionStart, async).
#
# Only adds missing servers; never removes undeclared ones, since the
# user-scope MCP config can also hold servers added manually or by other
# tools (unlike plugins.conf, which owns the full per-project plugin set).

set -uo pipefail

MCP_SERVERS_CONF="${HOME}/.config/claude/mcp-servers.conf"

[ ! -f "$MCP_SERVERS_CONF" ] && exit 0

while IFS= read -r line; do
  # strip comments/blank lines
  line="${line%%#*}"
  line="$(echo "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  [ -z "$line" ] && continue

  name="${line%% *}"
  rest="${line#* }"
  claude mcp get "$name" >/dev/null 2>&1 && continue

  # shellcheck disable=SC2086
  claude mcp add "$name" --scope user $rest 2>/dev/null || true
done <"$MCP_SERVERS_CONF"

exit 0
