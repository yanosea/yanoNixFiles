#
# init.zsh - zsh interactive shell configuration
# loaded for interactive zsh sessions
#

# determine config directory
if [[ -n "$ZDOTDIR" ]]; then
  ZSHRC_DIR="$ZDOTDIR/rc"
else
  ZSHRC_DIR="$HOME/.config/zsh/rc"
fi

# interactive shell configuration
source "$ZSHRC_DIR/interactive.zsh"

# external tools initialization
source "$ZSHRC_DIR/tools.zsh"

# aliases and shortcuts
source "$ZSHRC_DIR/abbreviations.zsh"

# credentials (interactive-only)
source "$ZSHRC_DIR/credentials.zsh"

# Preserve the login session environment (including the macOS keychain).
if [[ -z "${REMOTE_AGENTS_STARTED:-}" && -f "$HOME/.agents/remote-control.py" ]]; then
  export REMOTE_AGENTS_STARTED=1
  (
    mkdir -p "$XDG_CACHE_HOME/agents"
    python3 "$HOME/.agents/remote-control.py" start >>"$XDG_CACHE_HOME/agents/remote-control.log" 2>&1
  ) &|
fi

# zellij configuration
source "$ZSHRC_DIR/zellij.zsh"
