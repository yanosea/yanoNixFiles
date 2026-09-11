#!/usr/bin/env bash
# sync-plugins.sh - Reconcile installed Codex plugins to match the declarative
# list in ~/.config/codex/plugins.conf (SessionStart, async). Codex counterpart
# of configs/claude/hooks/sync-plugins.sh.
#
# plugins.conf is the single source of truth: anything not declared `[x]` there
# is uninstalled, whether it's explicitly excluded, newly appeared in a
# marketplace and not yet triaged, or a stale/renamed leftover.
#
# `codex plugin add`/`remove` record the result in config.toml itself, so this
# only works while that file is writable. Once it becomes a Nix-managed store
# symlink the `[plugins."<id>"]` tables have to be generated instead.

set -uo pipefail

PLUGINS_CONF="${CODEX_HOME:-$HOME/.config/codex}/plugins.conf"
CACHE_DIR="${HOME}/.cache/codex-plugin-sync"
MARKETPLACE_CACHE="${CACHE_DIR}/codex-plugins-available.json"
CACHE_TTL=86400 # 24 hours

mkdir -p "$CACHE_DIR"

[ ! -f "$PLUGINS_CONF" ] && exit 0
command -v codex >/dev/null 2>&1 || exit 0

# refresh the available-plugin snapshot that check-new-plugins.sh reads
FETCH_NEEDED=true
if [ -f "$MARKETPLACE_CACHE" ]; then
  if [[ $OSTYPE == "darwin"* ]]; then
    age=$(($(date +%s) - $(stat -f %m "$MARKETPLACE_CACHE")))
  else
    age=$(($(date +%s) - $(stat -c %Y "$MARKETPLACE_CACHE")))
  fi
  [ "$age" -lt "$CACHE_TTL" ] && FETCH_NEEDED=false
fi

if [ "$FETCH_NEEDED" = true ]; then
  codex plugin marketplace upgrade >/dev/null 2>&1 || true
  codex plugin list --available --json >"$MARKETPLACE_CACHE" 2>/dev/null || true
fi

DECLARED=" $(sed -nE 's/^\[x\] +([^ ]+).*/\1/p' "$PLUGINS_CONF" | tr '\n' ' ') "
INSTALLED=" $(codex plugin list --json 2>/dev/null |
  python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for p in data.get('installed', []):
    print(p['pluginId'])
" | tr '\n' ' ') "

in_list() {
  case "$1" in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

# uninstall first: it is the pass that must not be starved by a timeout
for id in $INSTALLED; do
  in_list "$DECLARED" "$id" || codex plugin remove "$id" >/dev/null 2>&1 || true
done

for id in $DECLARED; do
  in_list "$INSTALLED" "$id" || codex plugin add "$id" >/dev/null 2>&1 || true
done

exit 0
