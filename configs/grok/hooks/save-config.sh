#!/usr/bin/env bash
# save-config.sh - write the live config.toml and pager.toml back into the repo
# (SessionEnd).
# grok rewrites the file in its own format, so it is filtered by key: the
# config.local.toml keys and the state tables ([plugins], [privacy]) are dropped.

set -uo pipefail

cat >/dev/null

LIVE="${GROK_HOME:-$HOME/.config/grok}/config.toml"
REPO="$(ghq root 2>/dev/null || echo "$HOME/ghq")/github.com/yanosea/yanoNixFiles"
DEST="$REPO/configs/grok/config.toml"

# pager.toml carries no state, so it goes back as is
PAGER_LIVE="$(dirname "$LIVE")/pager.toml"
PAGER_DEST="$(dirname "$DEST")/pager.toml"
if [ -f "$PAGER_LIVE" ] && [ -f "$PAGER_DEST" ] && [ "$PAGER_LIVE" -nt "$PAGER_DEST" ]; then
  cmp -s "$PAGER_LIVE" "$PAGER_DEST" || cp "$PAGER_LIVE" "$PAGER_DEST"
fi

[ -f "$LIVE" ] || exit 0
[ -f "$DEST" ] || exit 0

# the repo is ahead and not applied yet
[ "$DEST" -nt "$LIVE" ] && exit 0

python3 - "$LIVE" "$DEST" "$(dirname "$LIVE")/config.local.toml" <<'PYEOF'
import os, re, sys

live_path, dest_path, local_path = sys.argv[1], sys.argv[2], sys.argv[3]

DROP = re.compile(r'^\[+(plugins|privacy)[.\]]')
KEY = re.compile(r'^\s*([A-Za-z0-9_.-]+|"[^"]*")\s*=')

local_keys = set()
if os.path.exists(local_path):
    for line in open(local_path, encoding='utf-8'):
        if line.startswith('['):
            break
        m = KEY.match(line)
        if m:
            local_keys.add(m.group(1))

kept, in_table, dropping = [], False, False
for line in open(live_path, encoding='utf-8'):
    if line.startswith('['):
        in_table, dropping = True, bool(DROP.match(line))
    elif not in_table:
        m = KEY.match(line)
        if m and m.group(1) in local_keys:
            continue
    if not dropping:
        kept.append(line)

new = ''.join(kept).strip() + '\n'

with open(dest_path, encoding='utf-8') as f:
    if f.read() == new:
        sys.exit(0)

with open(dest_path, 'w', encoding='utf-8') as f:
    f.write(new)
print(f'saved config.toml to {dest_path}', file=sys.stderr)
PYEOF

exit 0
