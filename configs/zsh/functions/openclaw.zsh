# openclaw functions
openclaw() {
  # the gateway keeps its state outside the cli default, so point the cli at it
  # rather than exporting the variable, which a session-start hook keys off
  local state="$XDG_STATE_HOME/openclaw"
  if [ -d "$state" ]; then
    OPENCLAW_STATE_DIR="$state" command openclaw "$@"
  else
    command openclaw "$@"
  fi
}
