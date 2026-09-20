#!/usr/bin/env bash
# sync-mcp-servers.sh - reconcile agy MCP servers with configs/claude/mcp-servers.conf.
# Run from the claude hook: agy skips its own hooks once ~30 plugins are loaded.

set -uo pipefail
# keep `mcp<2` unglobbed
set -f

MCP_SERVERS_CONF="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}/mcp-servers.conf"
MCP_CONFIG="${HOME}/.gemini/config/mcp_config.json"

[ ! -f "$MCP_SERVERS_CONF" ] && exit 0
command -v agy >/dev/null 2>&1 || exit 0

declared=""

while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  [ -z "$line" ] && continue

  name="${line%% *}"
  rest="${line#* }"
  declared="${declared} ${name}"

  case "$rest" in
  *" -- "* | "-- "*)
    flags="${rest%%-- *}"
    cmd="${rest#*-- }"
    ;;
  -*)
    flags="${rest% *}"
    cmd="${rest##* }"
    ;;
  *)
    flags=""
    cmd="$rest"
    ;;
  esac
  # agy detects the transport itself
  flags=$(echo " $flags " | sed -E 's/ (--transport|-t) [^ ]+ / /g')

  # shellcheck disable=SC2086
  agy mcp add $flags "$name" -- $cmd >/dev/null 2>&1 || true
done <"$MCP_SERVERS_CONF"

[ ! -s "$MCP_CONFIG" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

while IFS= read -r name; do
  [ -z "$name" ] && continue
  case " ${declared} " in
  *" ${name} "*) continue ;;
  esac
  agy mcp remove "$name" >/dev/null 2>&1 || true
done < <(jq -r '.mcpServers // {} | keys[]' "$MCP_CONFIG" 2>/dev/null)

exit 0
