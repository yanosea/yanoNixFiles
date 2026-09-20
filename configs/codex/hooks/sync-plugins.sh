#!/usr/bin/env bash
# sync-plugins.sh - Reconcile installed Codex plugins to match the declarative
# list in ~/.config/codex/plugins.conf (SessionStart, async). Codex counterpart
# of configs/claude/hooks/sync-plugins.sh.
#
# plugins.conf is the single source of truth: anything not declared `[x]` there
# is uninstalled, whether it's explicitly excluded, newly appeared in a
# marketplace and not yet triaged, or a stale/renamed leftover.
#
# Outdated plugins are re-added: codex has no update subcommand.
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
INSTALLED_JSON=$(codex plugin list --json 2>/dev/null || echo '{}')
INSTALLED=" $(echo "$INSTALLED_JSON" | jq -r '.installed[]?.pluginId' 2>/dev/null | tr '\n' ' ') "

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

OUTDATED=$(jq -r --argjson inst "$INSTALLED_JSON" '
  ($inst.installed // [] | map({(.pluginId): .version}) | add // {}) as $have
  | .available[]? | select($have[.pluginId] != null and .version != null
    and $have[.pluginId] != .version) | .pluginId' "$MARKETPLACE_CACHE" 2>/dev/null)
for id in $OUTDATED; do
  in_list "$DECLARED" "$id" && codex plugin add "$id" >/dev/null 2>&1 || true
done

exit 0
