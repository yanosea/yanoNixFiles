#!/usr/bin/env bash
# check-new-plugins.sh - report plugins undeclared in plugins.conf or gone upstream.
# Prints plain text for inject-context.sh: grok ignores SessionStart output.

set -uo pipefail

GROK_DIR="${GROK_HOME:-$HOME/.config/grok}"
PLUGINS_CONF="${GROK_DIR}/plugins.conf"

[ ! -f "$PLUGINS_CONF" ] && exit 0

python3 - "$PLUGINS_CONF" "$GROK_DIR" <<'PYEOF'
import glob, json, os, re, sys

conf_path, grok_dir = sys.argv[1], sys.argv[2]

declared = set()
with open(conf_path, encoding='utf-8') as f:
    for line in f:
        m = re.match(r'^\[[ x]\]\s+(\S+)', line)
        if m:
            declared.add(m.group(1))

# catalogs, not `grok plugin list`, which uses installed names (netlify-skills)
plugins, complete = [], True
manifests = glob.glob(os.path.join(grok_dir, 'marketplace-cache', '*', '.*-plugin', 'marketplace.json'))
for path in manifests:
    try:
        plugins += json.load(open(path, encoding='utf-8')).get('plugins', [])
    except Exception:
        complete = False
if not plugins:
    sys.exit(0)

known = {p['name'] for p in plugins if p.get('name')}
new = sorted(
    {(p['name'], p.get('category', 'uncategorized'), (p.get('description') or '')[:140])
     for p in plugins if p.get('name') not in declared},
    key=lambda x: x[0].lower(),
)
gone = sorted(declared - known) if complete else []

sections = []
if new:
    sections.append(
    f"{len(new)} Grok Build plugin(s) appeared in a configured marketplace "
    "since the last plugins.conf review:\n"
    + "\n".join(f"{n} [{c}]: {d}" for n, c, d in new)
    + "\n\nAsk the user (in Japanese) whether to add each as installed. Every "
    "user-facing part of that exchange must be in Japanese. For a small number "
    "ask one by one; for many, list them and ask in chat. Then update "
    "configs/grok/plugins.conf in the yanoNixFiles repository: add a "
    "`[x] name` line for ones they want, `[ ] name` for ones they don't (this "
    "is a declarative list -- undecided/unanswered ones must default to `[ ]`, "
    "never silently installed). plugins.conf is English-only regardless of the "
    "conversation language: write the trailing `# category` comment in English, "
    "reusing a label already present in the file -- never write Japanese into "
    "that file. Keep the entries in ASCII alphabetical order, pad the name so "
    "`#` lands on column 46 like the surrounding lines, and refresh the "
    "`# total: / enabled: / excluded:` counts in the header. The change takes "
    "effect on the next session's sync-plugins.sh run after `nix run .#update`."
    )
if gone:
    sections.append(
    f"{len(gone)} plugin(s) declared in plugins.conf no longer exist in any "
    "configured marketplace (removed or renamed upstream):\n"
    + "\n".join(gone)
    + "\n\nDelete those lines from configs/grok/plugins.conf and refresh the "
    "`# total: / enabled: / excluded:` counts in the header. No need to ask "
    "the user first, but report in Japanese which entries were dropped, "
    "flagging any that was `[x]`."
    )

print("\n\n".join(sections))
PYEOF

exit 0
