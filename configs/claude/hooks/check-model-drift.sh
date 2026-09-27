#!/usr/bin/env bash
# check-model-drift.sh - keep the model tier pins in lib/ai-models.nix in step
# with what Anthropic serves: surface a tier whose newest release is not the one
# pinned, and a pin that has disappeared from the listing, to Claude at session
# start.
#
# Fast/sync SessionStart hook: reads local files only, no network calls
# (sync-models.sh keeps the model listing cache fresh once a day).

set -uo pipefail

# only the openclaw gateway wrapper exports this; its agent has no use for
# model bookkeeping meant for interactive sessions
[ -n "${OPENCLAW_STATE_DIR:-}" ] && exit 0

SETTINGS="${HOME}/.config/claude/settings.json"
MODEL_CACHE="${HOME}/.cache/claude-model-sync/models.json"

[ ! -f "$SETTINGS" ] && exit 0
[ ! -s "$MODEL_CACHE" ] && exit 0

python3 - "$SETTINGS" "$MODEL_CACHE" <<'PYEOF'
import json, re, sys

settings_path, cache_path = sys.argv[1], sys.argv[2]

try:
    env = json.load(open(settings_path, encoding='utf-8')).get('env', {})
    models = json.load(open(cache_path, encoding='utf-8')).get('data', [])
except Exception:
    sys.exit(0)

# the `opusplan` slots: opus is plan mode, sonnet is execution. both are
# written by lib/ai-models.nix, whatever tier they actually name
slots = [
    ('plan mode', 'ANTHROPIC_DEFAULT_OPUS_MODEL'),
    ('execution and subagents', 'ANTHROPIC_DEFAULT_SONNET_MODEL'),
]
pinned = [(role, env[key]) for role, key in slots if env.get(key)]
if not pinned or not models:
    sys.exit(0)

def tier_of(model_id):
    m = re.match(r'^claude-([a-z]+)-', model_id)
    return m.group(1) if m else None

# newest release per tier, by the listing's own created_at
latest = {}
for m in models:
    mid, created = m.get('id', ''), m.get('created_at', '')
    tier = tier_of(mid)
    if not tier or not created:
        continue
    if tier not in latest or created > latest[tier][1]:
        latest[tier] = (mid, created, m.get('display_name', mid))

served = {m.get('id') for m in models}

stale, gone = [], []
for role, mid in pinned:
    if mid not in served:
        gone.append((role, mid))
        continue
    tier = tier_of(mid)
    if tier and tier in latest and latest[tier][0] != mid:
        stale.append((role, mid, latest[tier][0], latest[tier][2]))

if not stale and not gone:
    sys.exit(0)

sections = []
if stale:
    lines = [
        f"{role}: pinned {old}, but the {tier_of(old)} tier now serves {new} ({name})"
        for role, old, new, name in stale
    ]
    sections.append(
    f"{len(stale)} claude model tier pin(s) are behind the current release:\n"
    + "\n".join(lines)
    + "\n\nlib/ai-models.nix holds the tier list that drives all of these: the "
    "`opusplan` slots in the generated claude settings, the subagent pin, and "
    "openclaw's `model.primary`. Ask the user (in Japanese) whether to move "
    "each tier to the newer id. Every user-facing part of that exchange -- the "
    "chat text and any AskUserQuestion labels/descriptions -- must be in "
    "Japanese; lib/ai-models.nix itself stays English-only, so keep its "
    "comments in English. For a small number use AskUserQuestion; for many, "
    "list them and ask in chat. On yes, change only the `id` of that tier "
    "entry, leaving the tier order alone -- the order is the user's capability "
    "ranking, not something the listing can decide. Then tell them to run "
    "`make home` to deploy it. One caveat worth mentioning: a model released "
    "very recently may not be recognised by the installed claude-code yet "
    "(`[claude-code:unrecognized_model]` at startup); if that happens the fix "
    "is to wait for the daily flake.lock update to bring a newer "
    "`inputs.claude-code`, not to keep the old id."
    )

if gone:
    sections.append(
    f"{len(gone)} claude model pin(s) no longer appear in the model listing "
    "(retired upstream):\n"
    + "\n".join(f"{role}: {mid}" for role, mid in gone)
    + "\n\nThat id cannot be served any more, so the slot is broken until it "
    "moves. Report this in Japanese and ask the user which id to pin instead, "
    "showing the ids the listing does offer for that tier, then update "
    "lib/ai-models.nix and tell them to run `make home`."
    )

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(sections),
    }
}))
PYEOF

exit 0
