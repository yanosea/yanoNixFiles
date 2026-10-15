#!/usr/bin/env bash
# check-model-drift.sh - keep the model pins in config.toml in step with what
# the chatgpt login serves: surface a pin the catalog marks for an upgrade, a
# pin that has disappeared from the catalog, and any listed model the catalog
# shows for the first time, to Codex at session start.
#
# Fast/sync SessionStart hook: reads local files only, no network calls
# (codex itself refreshes models_cache.json from the models endpoint).

set -uo pipefail

CODEX_DIR="${CODEX_HOME:-$HOME/.config/codex}"
CONFIG="${CODEX_DIR}/config.toml"
MODEL_CACHE="${CODEX_DIR}/models_cache.json"
# every model slug already reported, so each new one is told once
SEEN="${XDG_STATE_HOME:-$HOME/.local/state}/codex/seen-models.json"

[ ! -f "$CONFIG" ] && exit 0
[ ! -s "$MODEL_CACHE" ] && exit 0

python3 - "$CONFIG" "$MODEL_CACHE" "$SEEN" <<'PYEOF'
import json, os, re, sys

config_path, cache_path, seen_path = sys.argv[1], sys.argv[2], sys.argv[3]

# a line scan, not tomllib: only two plain string keys are needed
values, table = {}, ''
try:
    for line in open(config_path, encoding='utf-8'):
        m = re.match(r'^\s*\[+\s*([^\]]+?)\s*\]+', line)
        if m:
            table = m.group(1)
            continue
        m = re.match(r'^\s*([A-Za-z0-9_]+)\s*=\s*"([^"]*)"', line)
        if m:
            values[(table, m.group(1))] = m.group(2)
    models = json.load(open(cache_path, encoding='utf-8')).get('models', [])
except Exception:
    sys.exit(0)

slots = [
    ('main agent', values.get(('', 'model'))),
    ('subagents', values.get(('agents', 'default_subagent_model'))),
]
pinned = [(role, mid) for role, mid in slots if mid]
if not pinned or not models:
    sys.exit(0)

by_slug = {m.get('slug'): m for m in models if m.get('slug')}
served = set(by_slug)

stale, gone = [], []
for role, mid in pinned:
    if mid not in served:
        gone.append((role, mid))
        continue
    # the catalog names a successor for a model it wants people off
    upgrade = (by_slug[mid].get('upgrade') or {}).get('model')
    if upgrade and upgrade != mid:
        name = (by_slug.get(upgrade) or {}).get('display_name', upgrade)
        stale.append((role, mid, upgrade, name))

# slugs the picker lists for the first time. the first run only records the
# catalog, so the models that already exist are not reported as new
try:
    seen = set(json.load(open(seen_path, encoding='utf-8')))
except FileNotFoundError:
    seen = None
except Exception:
    seen = set()
reported = {new for _, _, new, _ in stale}
fresh = [] if seen is None else [
    m for slug, m in sorted(by_slug.items())
    if slug not in seen and slug not in reported and m.get('visibility') == 'list'
]
if seen is None or fresh:
    os.makedirs(os.path.dirname(seen_path), exist_ok=True)
    with open(seen_path, 'w', encoding='utf-8') as f:
        json.dump(sorted((seen or set()) | served), f, indent=2)

if not stale and not gone and not fresh:
    sys.exit(0)

where = (
    "configs/codex/config.toml in the yanoNixFiles repository holds these pins "
    "(`model` for the main agent, `[agents] default_subagent_model` for "
    "subagents). The same ids are repeated in configs/opencode/opencode.jsonc "
    "(the `openai` provider block), so move those along with them."
)

sections = []
if stale:
    sections.append(
    f"{len(stale)} codex model pin(s) are marked for an upgrade in the model "
    "catalog:\n"
    + "\n".join(
        f"{role}: pinned {old}, the catalog points to {new} ({name})"
        for role, old, new, name in stale
    )
    + "\n\n" + where + " Ask the user (in Japanese) whether to move each pin "
    "to the newer id. Every user-facing part of that exchange must be in "
    "Japanese; the files themselves stay English-only. On yes, change only "
    "those ids, then tell them to run `make home` to deploy it."
    )

if gone:
    sections.append(
    f"{len(gone)} codex model pin(s) no longer appear in the model catalog "
    "(retired upstream):\n"
    + "\n".join(f"{role}: {mid}" for role, mid in gone)
    + "\n\nThat id cannot be served any more. Report this in Japanese and ask "
    "the user which id to pin instead, showing the listed ids the catalog "
    "offers. " + where + " Then tell them to run `make home`."
    )

if fresh:
    sections.append(
    f"{len(fresh)} codex model(s) appeared in the model catalog since the last "
    "check:\n"
    + "\n".join(
        f"{m['slug']} ({m.get('display_name', m['slug'])}): "
        f"{(m.get('description') or '')[:140]}" for m in fresh
    )
    + "\n\nTell the user in Japanese, in one short note at the start of your "
    "reply, which models are new, and ask whether they want any of them "
    "pinned. Change nothing unless they say so. " + where
    )

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(sections),
    }
}))
PYEOF

exit 0
