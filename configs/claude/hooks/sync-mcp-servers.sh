#!/usr/bin/env bash
# sync-mcp-servers.sh - Reconcile the user-scope MCP servers with the set
# declared in configs/claude/mcp-servers.conf (SessionStart, async).
#
# The conf file is authoritative: missing servers are added, undeclared ones are
# removed. User-scope MCP lives only in .claude.json, which Claude Code rewrites
# at runtime and Nix cannot manage, so this hook is what keeps it declarative.
# Use the project scope (`-s local`) for one-off servers; plugin-provided ones
# are not user-scope and are never touched.

set -uo pipefail

MCP_SERVERS_CONF="${HOME}/.config/claude/mcp-servers.conf"
CLAUDE_JSON="${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json"

[ ! -f "$MCP_SERVERS_CONF" ] && exit 0

declared=""

# --- add: declared but not registered ---------------------------------------
while IFS= read -r line; do
  # strip comments/blank lines
  line="${line%%#*}"
  line="$(echo "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  [ -z "$line" ] && continue

  name="${line%% *}"
  rest="${line#* }"
  declared="${declared} ${name}"

  claude mcp get "$name" >/dev/null 2>&1 && continue

  # shellcheck disable=SC2086
  claude mcp add "$name" --scope user $rest 2>/dev/null || true
done <"$MCP_SERVERS_CONF"

# --- remove: registered in user scope but not declared ----------------------
# .claude.json rather than `claude mcp list`, which mixes in plugin/project
# servers and health-checks every one.
[ ! -f "$CLAUDE_JSON" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

while IFS= read -r name; do
  [ -z "$name" ] && continue
  case " ${declared} " in
  *" ${name} "*) continue ;;
  esac
  claude mcp remove "$name" --scope user 2>/dev/null || true
done < <(jq -r '.mcpServers // {} | keys[]' "$CLAUDE_JSON" 2>/dev/null)

exit 0
