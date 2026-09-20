#!/usr/bin/env bash
# sync-plugins.sh - reconcile grok plugins with plugins.conf and update them
# daily (SessionStart). Detaches itself: grok hooks have no async option.

set -uo pipefail

if [ -z "${GROK_PLUGIN_SYNC_DETACHED:-}" ]; then
  cat >/dev/null
  if command -v setsid >/dev/null 2>&1; then
    GROK_PLUGIN_SYNC_DETACHED=1 setsid nohup bash "$0" </dev/null >/dev/null 2>&1 &
  else
    GROK_PLUGIN_SYNC_DETACHED=1 nohup bash "$0" </dev/null >/dev/null 2>&1 &
  fi
  exit 0
fi

GROK_DIR="${GROK_HOME:-$HOME/.config/grok}"
PLUGINS_CONF="${GROK_DIR}/plugins.conf"
CACHE_DIR="${HOME}/.cache/grok-plugin-sync"
CACHE_TTL=86400 # 24 hours
UPDATE_STAMP="${CACHE_DIR}/update.stamp"
UPDATE_TTL=86400 # 24 hours

mkdir -p "$CACHE_DIR"

[ ! -f "$PLUGINS_CONF" ] && exit 0
command -v grok >/dev/null 2>&1 || exit 0

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

FETCH_STAMP="${CACHE_DIR}/fetch.stamp"
FETCH_NEEDED=true
if [ -f "$FETCH_STAMP" ]; then
  [ "$(stamp_age "$FETCH_STAMP")" -lt "$CACHE_TTL" ] && FETCH_NEEDED=false
fi

if [ "$FETCH_NEEDED" = true ]; then
  grok plugin marketplace update >/dev/null 2>&1 && touch "$FETCH_STAMP"
fi

in_list() {
  case "$1" in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

DECLARED=" $(sed -nE 's/^\[x\] +([^ ]+).*/\1/p' "$PLUGINS_CONF" | tr '\n' ' ') "

# "catalog-name installed-name enabled" per plugin; the installed name can
# differ (netlify -> netlify-skills), so it is mapped back by source URL
STATE=$(
  python3 - "$GROK_DIR" \
    "$(grok plugin list --json 2>/dev/null)" \
    "$(grok inspect --json 2>/dev/null)" <<'PYEOF'
import glob, json, os, sys

grok_dir, listed, inspected = sys.argv[1], sys.argv[2], sys.argv[3]

def norm(url):
    url = (url or '').strip().rstrip('/')
    return url[:-4] if url.endswith('.git') else url

by_source, names = {}, set()
for path in glob.glob(os.path.join(grok_dir, 'marketplace-cache', '*', '.*-plugin', 'marketplace.json')):
    try:
        for p in json.load(open(path, encoding='utf-8')).get('plugins', []):
            src = p.get('source')
            if isinstance(src, dict):
                url = src.get('url') or (src.get('repo') and 'https://github.com/' + src['repo'])
            else:
                url = src
            names.add(p['name'])
            if url:
                by_source[norm(url)] = p['name']
    except Exception:
        pass

try:
    installed = json.loads(listed)
except Exception:
    installed = []
try:
    enabled = {p['name'] for p in json.loads(inspected).get('plugins', []) if p.get('enabled')}
except Exception:
    enabled = set()

for p in installed:
    name = p['name']
    # a repository can back several entries (mongodb, mongodb-atlas)
    catalog = name if name in names else by_source.get(norm(p.get('source')), name)
    print(catalog, name, int(name in enabled))
PYEOF
)

INSTALLED=" "
while read -r catalog name enabled; do
  [ -z "$catalog" ] && continue
  if ! in_list "$DECLARED" "$catalog"; then
    grok plugin uninstall "$name" --confirm >/dev/null 2>&1 || true
    continue
  fi
  INSTALLED="${INSTALLED}${catalog} "
  [ "$enabled" = 1 ] || grok plugin enable "$name" >/dev/null 2>&1 || true
done <<<"$STATE"

for name in $DECLARED; do
  in_list "$INSTALLED" "$name" || grok plugin install "$name" --trust >/dev/null 2>&1 || true
done

UPDATE_DUE=true
if [ -f "$UPDATE_STAMP" ]; then
  [ "$(stamp_age "$UPDATE_STAMP")" -lt "$UPDATE_TTL" ] && UPDATE_DUE=false
fi

if [ "$UPDATE_DUE" = true ]; then
  grok plugin update >/dev/null 2>&1 || true
  touch "$UPDATE_STAMP"
fi

exit 0
