#
# zellij configuration and auto-attach
#

# attach to the newest session whose listing line matches the grep args
attach_latest_session() {
  local session_name
  session_name=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep "$@" | grep -v '^[[:space:]]*$' | tail -1 | cut -d' ' -f1)
  [[ -n "$session_name" ]] || return 1
  exec zellij attach "$session_name"
}

# auto-attach to zellij session on interactive shell startup
# only if we're in a terminal and not already in zellij
if [[ -o interactive ]] && [[ -z "$ZELLIJ" ]] && [[ -n "$TERM" ]] && [[ "$TERM" != "dumb" ]]; then
  # check if zellij is available
  if command -v zellij &>/dev/null; then
    # active sessions first, then an EXITED one to resurrect
    attach_latest_session -v EXITED || attach_latest_session EXITED
    # no sessions exist, create new
    exec zellij
  fi
fi

