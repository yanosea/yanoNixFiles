#!/usr/bin/env bash
# check-new-plugins.sh - keep plugins.conf in step with the marketplaces:
# surface plugins not yet declared there, and declared entries whose plugin
# has disappeared upstream, to Codex at session start. Codex counterpart of
# configs/claude/hooks/check-new-plugins.sh.
#
# Fast/sync SessionStart hook: reads local files only, no network calls
# (sync-plugins.sh keeps the marketplace snapshot fresh once a day).

set -uo pipefail

PLUGINS_CONF="${CODEX_HOME:-$HOME/.config/codex}/plugins.conf"
MARKETPLACE_CACHE="${HOME}/.cache/codex-plugin-sync/codex-plugins-available.json"

[ ! -f "$PLUGINS_CONF" ] && exit 0
[ ! -s "$MARKETPLACE_CACHE" ] && exit 0

python3 - "$PLUGINS_CONF" "$MARKETPLACE_CACHE" <<'PYEOF'
import json, re, sys

conf_path, mp_path = sys.argv[1], sys.argv[2]

declared = set()
with open(conf_path, encoding='utf-8') as f:
    for line in f:
        m = re.match(r'^\[[ x]\]\s+(\S+)', line)
        if m:
            declared.add(m.group(1))

try:
    mp = json.load(open(mp_path, encoding='utf-8'))
except Exception:
    sys.exit(0)

plugins = mp.get('available', []) + mp.get('installed', [])
known = {p.get('pluginId') for p in plugins}

new = []
for p in plugins:
    pid = p.get('pluginId')
    if not pid or pid in declared:
        continue
    # skip ChatGPT apps
    if str((p.get('source') or {}).get('id', '')).startswith('plugin_asdk'):
        continue
    new.append((pid, (p.get('description') or '')[:140]))

gone = sorted(declared - known) if plugins else []

if not new and not gone:
    sys.exit(0)

sections = []
if new:
    new = sorted(set(new), key=lambda x: x[0].lower())
    sections.append(
    f"{len(new)} Codex plugin(s) are available in a configured marketplace but "
    "not yet declared in plugins.conf:\n"
    + "\n".join(f"{pid}: {d}" for pid, d in new)
    + "\n\nAsk the user (in Japanese) whether to add each as installed. Every "
    "user-facing part of that exchange -- the chat text and any question "
    "labels/descriptions -- must be in Japanese. For a small number ask one by "
    "one; for many, list them and ask in chat. Then update "
    "configs/codex/plugins.conf in the yanoNixFiles repository: add a "
    "`[x] <id>` line for ones they want, `[ ] <id>` for ones they don't (this "
    "is a declarative list -- undecided/unanswered ones must default to `[ ]`, "
    "never silently installed). plugins.conf is English-only regardless of the "
    "conversation language: write the trailing `# category` comment in "
    "English, using one of development, productivity, database, "
    "observability, security, uncategorized, deployment, design, automation, "
    "learning, geospatial, testing, migration, math -- never write Japanese "
    "into that file. Keep the entries in ASCII alphabetical order, pad the id "
    "so `#` lands on column 70 like the surrounding lines, and refresh the "
    "`# total: / enabled: / excluded:` counts in the header. A `[x]` line "
    "takes effect on the next session's sync-plugins.sh run after "
    "`nix run .#update`."
    )
if gone:
    sections.append(
    f"{len(gone)} plugin(s) declared in plugins.conf no longer exist in any "
    "configured marketplace (removed or renamed upstream):\n"
    + "\n".join(gone)
    + "\n\nDelete those lines from configs/codex/plugins.conf in the "
    "yanoNixFiles repository and refresh the "
    "`# total: / enabled: / excluded:` counts in the header. No need to ask "
    "the user first, but report in Japanese which entries were dropped, "
    "flagging any that was `[x]`. sync-plugins.sh uninstalls the leftovers."
    )

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(sections),
    }
}))
PYEOF

exit 0
