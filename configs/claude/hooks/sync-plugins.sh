#!/usr/bin/env bash
# sync-plugins.sh - Auto-install all official + superpowers Claude plugins
# Runs as an async SessionStart hook (non-blocking background execution)
#
# Uses --scope local to write to .claude/settings.local.json (writable)
# instead of --scope user which targets the Nix-managed read-only symlink.
# Since the hook runs on every session start, plugins are installed
# per-project and effectively become globally available.

set -uo pipefail

# plugins to skip (NixOS incompatible or managed via mcpServers, etc.)
SKIP_PLUGINS="ralph-loop lua-lsp serena"

CACHE_DIR="${HOME}/.cache/claude-plugin-sync"
MARKETPLACE_CACHE="${CACHE_DIR}/claude-plugins-official.json"
CACHE_TTL=86400 # 24 hours

mkdir -p "$CACHE_DIR"

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

[ ! -s "$MARKETPLACE_CACHE" ] && exit 0

# extract plugin names
PLUGINS=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    for p in data.get('plugins', []):
        print(p['name'])
except Exception:
    pass
" "$MARKETPLACE_CACHE" 2>/dev/null)

[ -z "$PLUGINS" ] && exit 0

# install all official plugins (idempotent - skips if already installed)
for plugin in $PLUGINS; do
  # skip incompatible plugins
  if echo "$SKIP_PLUGINS" | grep -qw "$plugin"; then
    continue
  fi
  claude plugin install "${plugin}@claude-plugins-official" --scope local 2>/dev/null || true
done

# ensure superpowers marketplace is registered
claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true

# install superpowers plugins
claude plugin install "superpowers@superpowers-marketplace" --scope local 2>/dev/null || true
claude plugin install "superpowers-chrome@superpowers-marketplace" --scope local 2>/dev/null || true

# explicitly disable skipped plugins (in case they were previously installed)
for plugin in $SKIP_PLUGINS; do
  claude plugin disable "${plugin}@claude-plugins-official" --scope local 2>/dev/null || true
done

# register serena as user-level MCP server (writes to ~/.claude.json, not Nix-managed)
# --upgrade ensures uvx checks for latest version on every MCP server startup
claude mcp add serena --scope user -- uvx --upgrade --from "git+https://github.com/oraios/serena" serena start-mcp-server --open-web-dashboard=false 2>/dev/null || true

exit 0
