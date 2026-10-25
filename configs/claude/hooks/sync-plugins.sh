#!/usr/bin/env bash
# sync-plugins.sh - Reconcile installed Claude Code plugins to match the
# declarative list in configs/claude/plugins.conf (SessionStart, async).
#
# Nix writes plugins.conf into enabledPlugins of the user settings, and
# Claude Code fetches what they enable on its own, so a plugin loads in every
# directory from the first session. This hook only drops the per-project
# installs an earlier version made with --scope local, and keeps the user
# installs updated. `claude plugin install --scope user` cannot run here,
# since it writes the Nix-managed read-only settings.json.
#
# plugins.conf is the single source of truth: anything not declared `[x]`
# there is left out of enabledPlugins and does not load, whether it's
# explicitly excluded, newly appeared in the marketplace and not yet
# triaged, or a stale/renamed leftover.
#
# Declared plugins are also updated to their latest version. One update costs
# ~4.5s, so a full pass over the declared set outruns this hook's timeout;
# instead each run spends UPDATE_BUDGET seconds from where the last one stopped.

set -uo pipefail

# keep any claude call on the subscription login; the sops api key would bill per token
unset ANTHROPIC_API_KEY

START_TS=$(date +%s)

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

PLUGINS_CONF="${HOME}/.config/claude/plugins.conf"
# plugin, marketplace, repository for every non-official plugin
MARKETPLACES_CONF="${HOME}/.config/claude/plugin-marketplaces.conf"
CACHE_DIR="${HOME}/.cache/claude-plugin-sync"
MARKETPLACE_CACHE="${CACHE_DIR}/claude-plugins-official.json"
CACHE_TTL=86400 # 24 hours
UPDATE_STAMP="${CACHE_DIR}/update.stamp"
UPDATE_CURSOR="${CACHE_DIR}/update.cursor"
UPDATE_TTL=86400  # 24 hours between full update cycles
UPDATE_BUDGET=200 # seconds from script start the update pass may consume

mkdir -p "$CACHE_DIR"

[ ! -f "$PLUGINS_CONF" ] && exit 0

# the plugin, marketplace, repository rows, comments and blanks dropped
third_party() {
  [ -f "$MARKETPLACES_CONF" ] && grep -vE '^[[:space:]]*(#|$)' "$MARKETPLACES_CONF"
}

stamp_age() {
  if [[ $OSTYPE == "darwin"* ]]; then
    echo $(($(date +%s) - $(stat -f %m "$1")))
  else
    echo $(($(date +%s) - $(stat -c %Y "$1")))
  fi
}

# refresh marketplace cache if stale
FETCH_NEEDED=true
if [ -f "$MARKETPLACE_CACHE" ]; then
  [ "$(stamp_age "$MARKETPLACE_CACHE")" -lt "$CACHE_TTL" ] && FETCH_NEEDED=false
fi

if [ "$FETCH_NEEDED" = true ]; then
  curl -sL \
    "https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json" \
    >"$MARKETPLACE_CACHE" 2>/dev/null || true

  # refresh marketplace listings to pick up latest plugin versions
  claude plugin marketplace update claude-plugins-official 2>/dev/null || true
  for mp in $(third_party | awk '{ print $2 }' | sort -u); do
    claude plugin marketplace update "$mp" 2>/dev/null || true
  done
fi

in_list() {
  case "$1" in *" $2 "*) return 0 ;; *) return 1 ;; esac
}

# parse declared install-wanted plugin names: lines like "[x] name  # ..."
DECLARED_X=" $(grep -E '^\[x\] ' "$PLUGINS_CONF" | sed -E 's/^\[x\] +([^ ]+).*/\1/' | tr '\n' ' ') "

[ "$DECLARED_X" = "  " ] && exit 0

# same names, indexable: the update pass resumes at a saved position
read -ra DECLARED_ARR <<<"$DECLARED_X"

# register a third-party marketplace once any of its plugins is wanted
for repo in $(third_party | while read -r name _ source; do
  in_list "$DECLARED_X" "$name" && echo "$source"
done | sort -u); do
  claude plugin marketplace add "$repo" 2>/dev/null || true
done

marketplace_for() {
  mp=$(third_party | awk -v p="$1" '$1 == p { print $2; exit }')
  echo "${mp:-claude-plugins-official}"
}

PLUGIN_LIST=$(claude plugin list --json 2>/dev/null || echo '[]')

# the per-project installs an earlier version of this hook made here
local_installs() {
  echo "$PLUGIN_LIST" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for p in data:
    if p.get('scope') == 'local' and p.get('projectPath') == '$cwd':
        print(p['id'])
"
}

# the user installs cover every directory, and nothing updates these any more
for id in $(local_installs); do
  claude plugin uninstall "$id" --scope local 2>/dev/null || true
done

# update the declared set, resuming where the last run ran out of budget. The
# stamp is only touched once the cursor wraps, so a cut-off cycle continues
# next session instead of waiting out the TTL half-finished.
UPDATE_DUE=true
if [ -f "$UPDATE_STAMP" ]; then
  [ "$(stamp_age "$UPDATE_STAMP")" -lt "$UPDATE_TTL" ] && UPDATE_DUE=false
fi

if [ "$UPDATE_DUE" = true ]; then
  cursor=$(cat "$UPDATE_CURSOR" 2>/dev/null || echo 0)
  case "$cursor" in '' | *[!0-9]*) cursor=0 ;; esac
  total=${#DECLARED_ARR[@]}
  [ "$cursor" -ge "$total" ] && cursor=0

  while [ "$cursor" -lt "$total" ]; do
    [ "$(($(date +%s) - START_TS))" -ge "$UPDATE_BUDGET" ] && break
    plugin="${DECLARED_ARR[$cursor]}"
    mp=$(marketplace_for "$plugin")
    claude plugin update "${plugin}@${mp}" --scope user 2>/dev/null || true
    cursor=$((cursor + 1))
  done

  if [ "$cursor" -ge "$total" ]; then
    touch "$UPDATE_STAMP"
    cursor=0
  fi
  echo "$cursor" >"$UPDATE_CURSOR"
fi

# Uninstalling leaves the plugin's files behind, and every version ever
# installed is kept, so prune the cache after the uninstall pass.
GC_STAMP="${CACHE_DIR}/cache-gc.stamp"
GC_TTL=86400

GC_NEEDED=true
if [ -f "$GC_STAMP" ]; then
  [ "$(stamp_age "$GC_STAMP")" -lt "$GC_TTL" ] && GC_NEEDED=false
fi

if [ "$GC_NEEDED" = true ]; then
  python3 - "$CACHE_DIR" <<'PY' 2>/dev/null || true
import json, os, shutil, sys, time

log_dir = sys.argv[1]
base = os.path.expanduser("~/.config/claude/plugins/cache")
manifest = os.path.expanduser("~/.config/claude/plugins/installed_plugins.json")
now = time.time()
GRACE = 3600  # leave anything a concurrent session may still be writing

# version names are unordered (1.9.0 sorts above 1.10.0, and many are commit
# shas), so only the manifest says which ones are still pinned.
try:
    with open(manifest) as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

keep = {
    os.path.realpath(e["installPath"])
    for entries in data.get("plugins", {}).values()
    for e in entries
    if e.get("installPath")
}
if not keep:
    sys.exit(0)


def pid_alive(name):
    if not name.isdigit():
        return False
    try:
        os.kill(int(name), 0)
    except OSError:
        return False
    return True


def markers(version_dir):
    try:
        return os.listdir(os.path.join(version_dir, ".in_use"))
    except OSError:
        return []


def sweep_markers(version_dir):
    # exited sessions leave their pid behind, plus a .tmp.* per atomic write
    d = os.path.join(version_dir, ".in_use")
    for name in markers(version_dir):
        if pid_alive(name):
            continue
        p = os.path.join(d, name)
        try:
            if now - os.path.getmtime(p) > GRACE:
                os.unlink(p)
        except OSError:
            pass


versions = 0
for marketplace in os.listdir(base):
    mp = os.path.join(base, marketplace)
    if marketplace.startswith("temp_") or not os.path.isdir(mp):
        continue
    for plugin in os.listdir(mp):
        pd = os.path.join(mp, plugin)
        if not os.path.isdir(pd):
            continue
        for version in os.listdir(pd):
            vd = os.path.join(pd, version)
            if not os.path.isdir(vd):
                continue
            if os.path.realpath(vd) in keep or any(map(pid_alive, markers(vd))):
                sweep_markers(vd)
                continue
            shutil.rmtree(vd, ignore_errors=True)
            versions += 1

# clones left behind by an interrupted marketplace fetch
temps = 0
for name in os.listdir(base):
    if not name.startswith("temp_"):
        continue
    p = os.path.join(base, name)
    try:
        if now - os.path.getmtime(p) < GRACE:
            continue
    except OSError:
        continue
    shutil.rmtree(p, ignore_errors=True)
    temps += 1

if versions or temps:
    stamp = time.strftime("%Y-%m-%dT%H:%M:%S")
    with open(os.path.join(log_dir, "cache-gc.log"), "a") as f:
        f.write(f"{stamp} pruned {versions} versions, {temps} temp dirs\n")
PY
  touch "$GC_STAMP"
fi

exit 0
