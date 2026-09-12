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

# Uninstalling leaves the plugin's files behind, and every version ever
# installed is kept, so prune the cache after the uninstall pass.
GC_STAMP="${CACHE_DIR}/cache-gc.stamp"
GC_TTL=86400

GC_NEEDED=true
if [ -f "$GC_STAMP" ]; then
  if [[ $OSTYPE == "darwin"* ]]; then
    age=$(($(date +%s) - $(stat -f %m "$GC_STAMP")))
  else
    age=$(($(date +%s) - $(stat -c %Y "$GC_STAMP")))
  fi
  [ "$age" -lt "$GC_TTL" ] && GC_NEEDED=false
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
