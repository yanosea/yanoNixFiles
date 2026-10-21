#!/usr/bin/env bash
# sync-plugins.sh - import the claude-format plugins declared in plugins.conf
# into agy from their marketplace sources, and uninstall the rest.
# Run from the opencode agent-sync plugin: agy skips its own hooks once ~30
# plugins are loaded.

set -uo pipefail

AGY_CONFIG="${HOME}/.gemini/config"
PLUGINS_CONF="${AGY_CONFIG}/plugins.conf"
MARKETPLACES_CONF="${AGY_CONFIG}/plugin-marketplaces.conf"
PLUGINS_DIR="${AGY_CONFIG}/plugins"
CACHE_DIR="${HOME}/.cache/antigravity-plugin-sync"
# declared name, agy name ("-" if not importable), source revision
STATE="${CACHE_DIR}/imported.tsv"
# plugins not in plugin-marketplaces.conf come from here
OFFICIAL="claude-plugins-official anthropics/claude-plugins-official"
# an unpinned checkout is fetched again after this many seconds
STALE=21600

mkdir -p "$CACHE_DIR/marketplaces" "$CACHE_DIR/sources"

[ ! -f "$PLUGINS_CONF" ] && exit 0
for tool in agy git jq; do
  command -v "$tool" >/dev/null 2>&1 || exit 0
done

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

# "<marketplace> <repository>" of a plugin
marketplace_for() {
  local row=""
  [ -f "$MARKETPLACES_CONF" ] &&
    row=$(awk -v n="$1" '!/^[[:space:]]*(#|$)/ && $1 == n { print $2, $3; exit }' "$MARKETPLACES_CONF")
  echo "${row:-$OFFICIAL}"
}

# check out rev (a sha or a ref; the default branch when empty) of url into
# dir, shallow. a sha already checked out, or a fresh unpinned checkout, is kept
checkout() {
  local url=$1 dir=$2 rev=${3:-}
  if [ -d "$dir/.git" ]; then
    if [[ $rev =~ ^[0-9a-f]{40}$ ]]; then
      [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" = "$rev" ] && return 0
    elif [ -z "$rev" ] && [ "$(stamp_age "$dir/.git/FETCH_HEAD" 2>/dev/null || echo "$STALE")" -lt "$STALE" ]; then
      return 0
    fi
  else
    rm -rf "$dir" && git init -q "$dir" >/dev/null 2>&1 || return 1
  fi
  GIT_TERMINAL_PROMPT=0 git -C "$dir" fetch -q --depth 1 "$url" "${rev:-HEAD}" 2>/dev/null &&
    git -C "$dir" checkout -q --detach FETCH_HEAD 2>/dev/null
}

# "<directory> <revision>" of a declared plugin, or nothing
plugin_source() {
  local name=$1 marketplace repository mp_dir entry kind url sub rev dir
  read -r marketplace repository <<<"$(marketplace_for "$name")"
  mp_dir="$CACHE_DIR/marketplaces/$marketplace"
  checkout "https://github.com/$repository.git" "$mp_dir" || return 0
  entry=$(jq -c --arg n "$name" '.plugins[]? | select(.name == $n) | .source' \
    "$mp_dir/.claude-plugin/marketplace.json" 2>/dev/null | head -n 1)
  [ -n "$entry" ] || return 0
  kind=$(jq -r 'if type == "string" then "path" else .source // "" end' <<<"$entry")
  case "$kind" in
  path)
    sub=$(jq -r '.' <<<"$entry")
    echo "$mp_dir/${sub#./} $(git -C "$mp_dir" rev-parse HEAD):${sub#./}"
    return 0
    ;;
  github) url="https://github.com/$(jq -r '.repo' <<<"$entry").git" ;;
  url | git-subdir) url=$(jq -r '.url' <<<"$entry") ;;
  *) return 0 ;;
  esac
  sub=$(jq -r '.path // ""' <<<"$entry")
  rev=$(jq -r '.sha // .ref // ""' <<<"$entry")
  dir="$CACHE_DIR/sources/$name"
  checkout "$url" "$dir" "$rev" || return 0
  echo "$dir/$sub $(git -C "$dir" rev-parse HEAD):$sub"
}

state_field() {
  awk -F'\t' -v n="$1" -v f="$2" '$1 == n { print $f }' "$STATE"
}

set_state() {
  awk -F'\t' -v n="$1" '$1 != n' "$STATE" >"$STATE.tmp" && mv "$STATE.tmp" "$STATE"
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$STATE"
}

# (re)import when new or updated upstream
for name in $DECLARED; do
  read -r path revision <<<"$(plugin_source "$name")"
  [ -n "${path:-}" ] && [ -d "$path" ] || continue
  agy_name=$(state_field "$name" 2)
  if [ "$(state_field "$name" 3)" = "$revision" ]; then
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
  set_state "$name" "${agy_name:--}" "$revision"
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

# the plugins.conf review that the opencode agent-sync plugin shows the agent:
# official plugins the catalog does not list yet, and listed ones gone upstream
NOTICE="${CACHE_DIR}/notice.txt"
read -r official_mp official_repo <<<"$OFFICIAL"
checkout "https://github.com/$official_repo.git" "$CACHE_DIR/marketplaces/$official_mp" || true
LISTED=" $(sed -nE 's/^\[[ x]\] +([^ ]+).*/\1/p' "$PLUGINS_CONF" | tr '\n' ' ') "
new=""
gone=""
official_json="$CACHE_DIR/marketplaces/$official_mp/.claude-plugin/marketplace.json"
for name in $(jq -r '.plugins[]?.name' "$official_json" 2>/dev/null); do
  in_list "$LISTED" "$name" || new="${new}${name}"$'\n'
done
for name in $LISTED; do
  read -r marketplace _ <<<"$(marketplace_for "$name")"
  # a marketplace not fetched yet, or unreadable, says nothing about its plugins
  found=$(jq -r --arg n "$name" 'any(.plugins[]?; .name == $n)' \
    "$CACHE_DIR/marketplaces/$marketplace/.claude-plugin/marketplace.json" 2>/dev/null)
  [ "$found" = "false" ] && gone="${gone}${name}"$'\n'
done
if [ -z "$new$gone" ]; then
  rm -f "$NOTICE"
else
  {
    [ -n "$new" ] && printf '%s\n%s\n' "New in the official claude-format marketplace, not yet listed in configs/antigravity/plugins.conf of the yanoNixFiles repository:" "$new"
    [ -n "$gone" ] && printf '%s\n%s\n' "Listed in configs/antigravity/plugins.conf but gone from their marketplace:" "$gone"
    # shellcheck disable=SC2016 # backticks are literal text for the agent
    printf '%s\n' 'Ask the user (in Japanese) about each new plugin and add it as `[x] name` or `[ ] name` (undecided ones stay `[ ]`), in ASCII order with the `#` column and an English category comment like the surrounding lines, and refresh the header counts. Delete the gone ones (a shared one is declared in configs/agents/plugins.conf instead) and tell the user which were dropped. Changes apply after `nix run .#update`.'
  } >"$NOTICE.tmp" && mv "$NOTICE.tmp" "$NOTICE"
fi

exit 0
