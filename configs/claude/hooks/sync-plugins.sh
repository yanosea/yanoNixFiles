#!/usr/bin/env bash
# sync-plugins.sh - Reconcile installed Claude Code plugins to match the
# declarative list in configs/claude/plugins.conf (SessionStart, async).
#
# Uses --scope local to write to .claude/settings.local.json (writable)
# instead of --scope user which targets the Nix-managed read-only symlink.
# Since the hook runs on every session start, plugins converge to the
# declared state per-project over time.
#
# plugins.conf is the single source of truth: anything not declared `[x]`
# there is uninstalled, whether it's explicitly excluded, newly appeared
# in the marketplace and not yet triaged, or a stale/renamed leftover.

set -uo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

PLUGINS_CONF="${HOME}/.config/claude/plugins.conf"
CACHE_DIR="${HOME}/.cache/claude-plugin-sync"
MARKETPLACE_CACHE="${CACHE_DIR}/claude-plugins-official.json"
CACHE_TTL=86400 # 24 hours

mkdir -p "$CACHE_DIR"

[ ! -f "$PLUGINS_CONF" ] && exit 0

# refresh marketplace cache if stale
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
  curl -sL \
    "https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json" \
    >"$MARKETPLACE_CACHE" 2>/dev/null || true

  # refresh marketplace listings to pick up latest plugin versions
  claude plugin marketplace update claude-plugins-official 2>/dev/null || true
  claude plugin marketplace update superpowers-marketplace 2>/dev/null || true
fi

# plugin names sourced from the superpowers-marketplace rather than the
# official one (upstream, not a possibly-stale mirror)
SUPERPOWERS_PLUGINS=" superpowers superpowers-chrome "

in_list() {
  case "$1" in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

# parse declared install-wanted plugin names: lines like "[x] name  # ..."
DECLARED_X=" $(grep -E '^\[x\] ' "$PLUGINS_CONF" | sed -E 's/^\[x\] +([^ ]+).*/\1/' | tr '\n' ' ') "

[ "$DECLARED_X" = "  " ] && exit 0

# ensure superpowers marketplace is registered if any of its plugins are wanted
if in_list "$SUPERPOWERS_PLUGINS" "superpowers" || in_list "$SUPERPOWERS_PLUGINS" "superpowers-chrome"; then
  if in_list "$DECLARED_X" "superpowers" || in_list "$DECLARED_X" "superpowers-chrome"; then
    claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
  fi
fi

marketplace_for() {
  if in_list "$SUPERPOWERS_PLUGINS" "$1"; then
    echo "superpowers-marketplace"
  else
    echo "claude-plugins-official"
  fi
}

# Snapshot once: `claude plugin install` costs ~2.5s even when already installed,
# so looping it over every declared name outran this hook's 300s timeout.
PLUGIN_LIST=$(claude plugin list --json 2>/dev/null || echo '[]')

plugin_names() {
  # $1: "any" = installed for this project, "enabled" = that subset, enabled.
  echo "$PLUGIN_LIST" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cwd = '$cwd'
want_enabled = '$1' == 'enabled'
seen = set()
for p in data:
    if p.get('projectPath') != cwd:
        continue
    if want_enabled and not p.get('enabled'):
        continue
    name = p['id'].split('@', 1)[0]
    if name not in seen:
        seen.add(name)
        print(name)
"
}

PRESENT=" $(plugin_names any | tr '\n' ' ') "
ENABLED_NOW=" $(plugin_names enabled | tr '\n' ' ') "

# uninstall first: it is the pass that must not be starved by a timeout
for installed_name in $ENABLED_NOW; do
  if ! in_list "$DECLARED_X" "$installed_name"; then
    mp=$(marketplace_for "$installed_name")
    claude plugin uninstall "${installed_name}@${mp}" --scope local 2>/dev/null || true
  fi
done

# install what is declared but absent, enable what is present but off
for plugin in $DECLARED_X; do
  mp=$(marketplace_for "$plugin")
  if ! in_list "$PRESENT" "$plugin"; then
    claude plugin install "${plugin}@${mp}" --scope local 2>/dev/null || true
  elif ! in_list "$ENABLED_NOW" "$plugin"; then
    claude plugin enable "${plugin}@${mp}" --scope local 2>/dev/null || true
  fi
done

exit 0
