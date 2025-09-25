#
# .zshrc - zsh interactive shell configuration
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

# zellij configuration
source "$ZSHRC_DIR/zellij.zsh"

# display random ascii art
show_random_aa

