#!/usr/bin/env bash
# save-config.sh - write the live config.toml back into the yanoNixFiles repo
# (SessionEnd), so settings changed from the TUI (/statusline, /theme, /model,
# keymaps) survive the next `nix run .#home`.
#
# config.toml is deployed as a copy rather than a store symlink because codex
# has to write to it; that copy is replaced on every home-manager activation, so
# without this the TUI's own changes are silently lost. Two things are dropped on
# the way in: the config.local.toml block activation prepends, and the runtime
# state ([hooks.state] is keyed by the config path, [projects.*] is per-machine
# trust) -- none of it belongs in the repo.
#
# Runs by hand too: bash ~/.config/codex/hooks/save-config.sh

set -uo pipefail

LIVE="${CODEX_HOME:-$HOME/.config/codex}/config.toml"
REPO="$(ghq root 2>/dev/null || echo "$HOME/ghq")/github.com/yanosea/yanoNixFiles"
DEST="$REPO/configs/codex/config.toml"

[ -f "$LIVE" ] || exit 0
[ -f "$DEST" ] || exit 0

# a repo copy newer than the live one means the repo is ahead and not applied
# yet; writing back here would silently revert those edits
[ "$DEST" -nt "$LIVE" ] && exit 0

python3 - "$LIVE" "$DEST" <<'PYEOF'
import re, sys

live_path, dest_path = sys.argv[1], sys.argv[2]

# headers whose whole section is machine state, not configuration
DROP = re.compile(r'^\[+(hooks\.state|projects)[.\]]')

lines = open(live_path, encoding='utf-8').readlines()

# activation prepends config.local.toml, which must never reach the repo; the
# repo copy starts at its own first line, so cut everything above it
marker = open(dest_path, encoding='utf-8').readline()
try:
    lines = lines[lines.index(marker):]
except ValueError:
    sys.exit(0)

kept, dropping = [], False
for line in lines:
    if re.match(r'^\[', line):
        dropping = bool(DROP.match(line))
    if not dropping:
        kept.append(line)

new = ''.join(kept).rstrip() + '\n'

with open(dest_path, encoding='utf-8') as f:
    if f.read() == new:
        sys.exit(0)

with open(dest_path, 'w', encoding='utf-8') as f:
    f.write(new)
print(f'saved config.toml to {dest_path}', file=sys.stderr)
PYEOF

exit 0
