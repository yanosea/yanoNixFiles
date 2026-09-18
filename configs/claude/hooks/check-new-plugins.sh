#!/usr/bin/env bash
# check-new-plugins.sh - keep plugins.conf in step with the marketplaces:
# surface plugins not yet declared there, and declared entries whose plugin
# has disappeared upstream, to Claude at session start.
#
# Fast/sync SessionStart hook: reads local files only, no network calls
# (sync-plugins.sh keeps the marketplace cache fresh once a day).

set -uo pipefail

PLUGINS_CONF="${HOME}/.config/claude/plugins.conf"
MARKETPLACE_CACHE="${HOME}/.cache/claude-plugin-sync/claude-plugins-official.json"
# every registered marketplace, so entries from non-official ones (superpowers)
# are not mistaken for removals; new-plugin detection stays official-only.
MARKETPLACE_DIR="${HOME}/.config/claude/plugins/marketplaces"

[ ! -f "$PLUGINS_CONF" ] && exit 0
[ ! -s "$MARKETPLACE_CACHE" ] && exit 0

python3 - "$PLUGINS_CONF" "$MARKETPLACE_CACHE" "$MARKETPLACE_DIR" <<'PYEOF'
import glob, json, os, re, sys

conf_path, mp_path, mp_dir = sys.argv[1], sys.argv[2], sys.argv[3]

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

# A declared entry is only "removed" once every registered marketplace has been
# read; one unparsable manifest would otherwise flag its whole catalog as gone.
known, complete = set(), True
manifests = glob.glob(os.path.join(mp_dir, '*', '.claude-plugin', 'marketplace.json'))
for path in manifests:
    try:
        known |= {p['name'] for p in json.load(open(path, encoding='utf-8')).get('plugins', [])}
    except Exception:
        complete = False
gone = sorted(declared - known) if manifests and complete and known else []

if not new and not gone:
    sys.exit(0)

sections = []
if new:
    lines = [f"{n} [{c}]: {d}" for n, c, d in sorted(new, key=lambda x: x[0].lower())]
    sections.append(
    f"{len(new)} new Claude Code plugin(s) appeared in the official marketplace "
    "since the last plugins.conf review:\n"
    + "\n".join(lines)
    + "\n\nAsk the user (in Japanese) whether to add each as installed. Every "
    "user-facing part of that exchange -- the chat text and any "
    "AskUserQuestion labels/descriptions -- must be in Japanese. For a small "
    "number use AskUserQuestion; for many, list them and ask in chat. "
    "Then update configs/claude/plugins.conf: add a `[x] name` line for ones "
    "they want, `[ ] name` for ones they don't (this is a declarative list -- "
    "undecided/unanswered ones must default to `[ ]`, never silently "
    "installed). plugins.conf is English-only regardless of the conversation "
    "language: write the trailing `# category` comment in English, reusing a "
    "label already present in the file (development, productivity, database, "
    "observability, security, uncategorized, deployment, design, automation, "
    "learning, geospatial, testing, migration, math) -- never write Japanese "
    "into that file. Keep the entries in ASCII alphabetical order, pad the "
    "name so `#` lands on column 46 like the surrounding lines, and refresh "
    "the `# total: / enabled: / excluded:` counts in the header. The change "
    "takes effect on the next session's sync-plugins.sh run."
    )

if gone:
    sections.append(
    f"{len(gone)} plugin(s) declared in plugins.conf no longer exist in any "
    "registered marketplace (removed or renamed upstream):\n"
    + "\n".join(gone)
    + "\n\nDelete those lines from configs/claude/plugins.conf and refresh the "
    "`# total: / enabled: / excluded:` counts in the header. No need to ask "
    "the user first -- the plugin is gone, so the entry cannot be acted on "
    "either way -- but report in Japanese which entries were dropped. Any of "
    "them that was `[x]` is also worth flagging: the user was relying on it. "
    "sync-plugins.sh uninstalls the leftover files on its own."
    )

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n\n".join(sections),
    }
}))
PYEOF

exit 0
