#!/usr/bin/env bash
# sync-plugins.sh - import the claude plugins declared in plugins.conf into agy
# from the claude plugin cache (agy has no marketplace) and uninstall the rest.
# Run from the claude hook: agy skips its own hooks once ~30 plugins are loaded.

set -uo pipefail

AGY_CONFIG="${HOME}/.gemini/config"
PLUGINS_CONF="${AGY_CONFIG}/plugins.conf"
PLUGINS_DIR="${AGY_CONFIG}/plugins"
CLAUDE_MANIFEST="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}/plugins/installed_plugins.json"
CACHE_DIR="${HOME}/.cache/antigravity-plugin-sync"
# claude name, agy name ("-" if not importable), install path
STATE="${CACHE_DIR}/imported.tsv"

mkdir -p "$CACHE_DIR"

[ ! -f "$PLUGINS_CONF" ] && exit 0
[ ! -f "$CLAUDE_MANIFEST" ] && exit 0
command -v agy >/dev/null 2>&1 || exit 0

stamp_age() {
  if [[ $OSTYPE == "darwin"* ]]; then
    echo $(($(date +%s) - $(stat -f %m "$1")))
  else
    echo $(($(date +%s) - $(stat -c %Y "$1")))
  fi
}

# mkdir lock: macOS has no flock
LOCK_DIR="${CACHE_DIR}/sync.lock"
if [ -d "$LOCK_DIR" ] && [ "$(stamp_age "$LOCK_DIR")" -gt 3600 ]; then
  rmdir "$LOCK_DIR" 2>/dev/null
fi
mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

touch "$STATE"

in_list() {
  case "$1" in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

DECLARED=" $(sed -nE 's/^\[x\] +([^ ]+).*/\1/p' "$PLUGINS_CONF" | tr '\n' ' ') "

install_path() {
  jq -r --arg n "$1" '
    [.plugins // {} | to_entries[] | select(.key | split("@")[0] == $n) | .value[]]
    | sort_by(.lastUpdated // "") | last | .installPath // empty
  ' "$CLAUDE_MANIFEST" 2>/dev/null
}

state_field() {
  awk -F'\t' -v n="$1" -v f="$2" '$1 == n { print $f }' "$STATE"
}

set_state() {
  awk -F'\t' -v n="$1" '$1 != n' "$STATE" >"$STATE.tmp" && mv "$STATE.tmp" "$STATE"
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$STATE"
}

# (re)import when new or updated on the claude side
for name in $DECLARED; do
  path=$(install_path "$name")
  [ -n "$path" ] && [ -d "$path" ] || continue
  agy_name=$(state_field "$name" 2)
  if [ "$(state_field "$name" 3)" = "$path" ]; then
    [ "$agy_name" = "-" ] && continue
    [ -n "$agy_name" ] && [ -d "$PLUGINS_DIR/$agy_name" ] && continue
  fi
  # plugin parts only: some are whole monorepos, and .git may hold dangling links
  stage="$(mktemp -d)/$name"
  mkdir -p "$stage"
  keep=".claude-plugin skills agents commands scripts bin .mcp.json plugin.json"
  keep="$keep $(jq -r '[.. | strings | select(startswith("./")) | ltrimstr("./")
    | split("/")[0]] | unique | join(" ")' "$path/.claude-plugin/plugin.json" 2>/dev/null)"
  for entry in $keep; do
    [ -e "$path/$entry" ] || continue
    tar -C "$path" --exclude=.git --exclude=node_modules -cf - "$entry" | tar -C "$stage" -xf -
  done
  # claude's hooks.json breaks every agy hook, and its events do not exist in agy
  rm -f "$stage/hooks/hooks.json"
  manifest="$stage/.claude-plugin/plugin.json"
  if [ -f "$manifest" ] && jq -e 'has("hooks")' "$manifest" >/dev/null 2>&1; then
    jq 'del(.hooks)' "$manifest" >"$manifest.tmp" && mv "$manifest.tmp" "$manifest"
  fi
  out=$(agy plugin import --force "$stage" 2>&1)
  rm -rf "$(dirname "$stage")"
  agy_name=$(echo "$out" | sed -E 's/\x1b\[[0-9;]*m//g' | sed -nE 's/^ *\[ok\] +([^ ]+).*/\1/p' | head -n 1)
  set_state "$name" "${agy_name:--}" "$path"
done

WANTED=" "
while IFS=$'\t' read -r name agy_name _; do
  in_list "$DECLARED" "$name" && [ "$agy_name" != "-" ] && WANTED="${WANTED}${agy_name} "
done <"$STATE"

for dir in "$PLUGINS_DIR"/*/; do
  [ -d "$dir" ] || continue
  agy_name=$(basename "$dir")
  in_list "$WANTED" "$agy_name" || agy plugin uninstall "$agy_name" >/dev/null 2>&1 || true
done

exit 0
