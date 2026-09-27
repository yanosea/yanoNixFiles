#!/usr/bin/env bash
# sync-models.sh - Cache the Anthropic model list for check-model-drift.sh
# (SessionStart, async).
#
# The model ids that lib/ai-models.nix pins cannot be aliases:
# ANTHROPIC_DEFAULT_OPUS_MODEL and friends reject `opus`/`fable` and take a full
# id only, so a new release in a tier has to be noticed and written in. This
# hook keeps a once-a-day snapshot of GET /v1/models on disk; the drift check
# itself reads only that file, so a session never waits on the network.
#
# Unlike the other sync hooks this one does use the sops ANTHROPIC_API_KEY: the
# models endpoint is metadata, not inference, so it bills nothing. It is never
# used to run a model.

set -uo pipefail

# only the openclaw gateway wrapper exports this; its agent has no use for
# model bookkeeping meant for interactive sessions
[ -n "${OPENCLAW_STATE_DIR:-}" ] && exit 0

API_KEY_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/sops/ANTHROPIC_API_KEY"
CACHE_DIR="${HOME}/.cache/claude-model-sync"
MODEL_CACHE="${CACHE_DIR}/models.json"
CACHE_TTL=86400 # 24 hours

# a hook process starts from launchd/the cli, not a login shell, so the key is
# read from the sops file rather than the environment credentials.zsh exports
[ ! -s "$API_KEY_FILE" ] && exit 0

mkdir -p "$CACHE_DIR"

stamp_age() {
  if [[ $OSTYPE == "darwin"* ]]; then
    echo $(($(date +%s) - $(stat -f %m "$1")))
  else
    echo $(($(date +%s) - $(stat -c %Y "$1")))
  fi
}

if [ -s "$MODEL_CACHE" ] && [ "$(stamp_age "$MODEL_CACHE")" -lt "$CACHE_TTL" ]; then
  exit 0
fi

TMP="${MODEL_CACHE}.tmp"

curl -s --max-time 20 \
  "https://api.anthropic.com/v1/models?limit=100" \
  -H "x-api-key: $(cat "$API_KEY_FILE")" \
  -H "anthropic-version: 2023-06-01" \
  >"$TMP" 2>/dev/null

# an error body is valid json too, so replace the cache only for a real listing
if jq -e '.data | arrays and length > 0' "$TMP" >/dev/null 2>&1; then
  mv "$TMP" "$MODEL_CACHE"
else
  rm -f "$TMP"
fi

exit 0
