#!/usr/bin/env bash
# check-new-plugins.sh - detect marketplace plugins not yet declared in
# plugins.conf and surface them to Claude at session start, so it can ask
# the user whether to add them.
#
# Fast/sync SessionStart hook: reads local files only, no network calls
# (sync-plugins.sh keeps the marketplace cache fresh once a day).

set -uo pipefail

PLUGINS_CONF="${HOME}/.config/claude/plugins.conf"
MARKETPLACE_CACHE="${HOME}/.cache/claude-plugin-sync/claude-plugins-official.json"

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

new = []
for p in mp.get('plugins', []):
    name = p['name']
    if name not in declared:
        new.append((name, p.get('category', 'uncategorized'), (p.get('description') or '')[:140]))

if not new:
    sys.exit(0)

lines = [f"{n} [{c}]: {d}" for n, c, d in sorted(new, key=lambda x: x[0].lower())]
ctx = (
    f"{len(new)} new Claude Code plugin(s) appeared in the official marketplace "
    "since the last plugins.conf review:\n"
    + "\n".join(lines)
    + "\n\nAsk the user (in Japanese) whether to add each as installed. For a "
    "small number use AskUserQuestion; for many, list them and ask in chat. "
    "Then update configs/claude/plugins.conf: add a `[x] name` line for ones "
    "they want, `[ ] name` for ones they don't (this is a declarative list — "
    "undecided/unanswered ones must default to `[ ]`, never silently "
    "installed). The change takes effect on the next session's "
    "sync-plugins.sh run."
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": ctx,
    }
}))
PYEOF

exit 0
