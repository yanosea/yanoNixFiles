#!/usr/bin/env bash
# check-model-drift.sh - keep the default model in config.toml in step with what
# the supergrok login serves: report a default that has disappeared from the
# model list, and any model the list shows for the first time. No "newer
# release" check: the list carries no release dates to tell one.
# Prints plain text for inject-context.sh: grok ignores SessionStart output.
#
# Reads local files only, no network calls (grok itself refreshes
# models_cache.json from the models endpoint).

set -uo pipefail

# openclaw-feeds runs grok unattended: no model bookkeeping
[ -n "${OPENCLAW_FEEDS:-}" ] && exit 0

GROK_DIR="${GROK_HOME:-$HOME/.config/grok}"
CONFIG="${GROK_DIR}/config.toml"
MODEL_CACHE="${GROK_DIR}/models_cache.json"
# every model id already reported, so each new one is told once
SEEN="${XDG_STATE_HOME:-$HOME/.local/state}/grok/seen-models.json"

[ ! -f "$CONFIG" ] && exit 0
[ ! -s "$MODEL_CACHE" ] && exit 0

python3 - "$CONFIG" "$MODEL_CACHE" "$SEEN" <<'PYEOF'
import json, os, re, sys

config_path, cache_path, seen_path = sys.argv[1], sys.argv[2], sys.argv[3]

# a line scan, not tomllib: only `[models] default` is needed
pinned, table = None, ''
try:
    for line in open(config_path, encoding='utf-8'):
        m = re.match(r'^\s*\[+\s*([^\]]+?)\s*\]+', line)
        if m:
            table = m.group(1)
            continue
        m = re.match(r'^\s*default\s*=\s*"([^"]*)"', line)
        if m and table == 'models':
            pinned = m.group(1)
    models = json.load(open(cache_path, encoding='utf-8')).get('models', {})
except Exception:
    sys.exit(0)

if not isinstance(models, dict) or not models:
    sys.exit(0)

info = {mid: (m or {}).get('info', {}) for mid, m in models.items()}
served = set(info)

gone = pinned if pinned and pinned not in served else None

# ids the list shows for the first time. the first run only records the list,
# so the models that already exist are not reported as new
try:
    seen = set(json.load(open(seen_path, encoding='utf-8')))
except FileNotFoundError:
    seen = None
except Exception:
    seen = set()
fresh = [] if seen is None else [
    mid for mid in sorted(served)
    if mid not in seen and not info[mid].get('hidden')
]
if seen is None or fresh:
    os.makedirs(os.path.dirname(seen_path), exist_ok=True)
    with open(seen_path, 'w', encoding='utf-8') as f:
        json.dump(sorted((seen or set()) | served), f, indent=2)

if not gone and not fresh:
    sys.exit(0)

where = (
    "configs/grok/config.toml in the yanoNixFiles repository pins it as "
    "`[models] default`, and configs/opencode/opencode.jsonc repeats it as the "
    "top-level `model` (`xai/<id>`), so move both together."
)

sections = []
if gone:
    sections.append(
    f"The default grok model {gone} no longer appears in the model list "
    "(retired upstream). Report this in Japanese and ask the user which id to "
    "pin instead, showing the ids the list does offer: "
    + ", ".join(sorted(mid for mid in served if not info[mid].get('hidden')))
    + ". " + where + " Then tell them to run `make home`."
    )

if fresh:
    sections.append(
    f"{len(fresh)} grok model(s) appeared in the model list since the last "
    "check:\n"
    + "\n".join(
        f"{mid} ({info[mid].get('name', mid)}): "
        f"{(info[mid].get('description') or '')[:140]}" for mid in fresh
    )
    + f"\n\nThe current default is {pinned or 'not set'}. Tell the user in "
    "Japanese, in one short note at the start of your reply, which models are "
    "new, and ask whether to make one of them the default. Change nothing "
    "unless they say so. " + where + " The files stay English-only; on a "
    "change, tell them to run `make home`."
    )

print("\n\n".join(sections))
PYEOF

exit 0
