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

# install everything declared [x]
for plugin in $DECLARED_X; do
  mp=$(marketplace_for "$plugin")
  claude plugin install "${plugin}@${mp}" --scope local 2>/dev/null || true
done

# uninstall anything installed for this project that isn't declared [x]
# (covers explicitly-excluded, undecided-new, and stale/renamed entries alike)
claude plugin list --json 2>/dev/null |
  python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cwd = '$cwd'
seen = set()
for p in data:
    if p.get('projectPath') != cwd or not p.get('enabled'):
        continue
    name = p['id'].split('@', 1)[0]
    if name not in seen:
        seen.add(name)
        print(name)
" |
  while IFS= read -r installed_name; do
    if ! in_list "$DECLARED_X" "$installed_name"; then
      mp=$(marketplace_for "$installed_name")
      claude plugin uninstall "${installed_name}@${mp}" --scope local 2>/dev/null || true
    fi
  done

exit 0
