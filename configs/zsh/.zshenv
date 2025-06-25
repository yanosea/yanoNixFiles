#
# .zshenv - zsh environment file
# loaded for all zsh sessions (login, interactive, non-interactive)
#

# load .zshrc for interactive features
[[ -f ./.zshrc ]] && . ./.zshrc

# determine config directory
if [[ -n "$ZDOTDIR" ]]; then
	ZSHENV_DIR="$ZDOTDIR/env"
else
	ZSHENV_DIR="$HOME/.config/zsh/env"
fi

# system and basic environment
source "$ZSHENV_DIR/system.zsh"
source "$ZSHENV_DIR/editor.zsh"
source "$ZSHENV_DIR/terminal.zsh"

# paths and development environment
source "$ZSHENV_DIR/paths.zsh"
source "$ZSHENV_DIR/languages.zsh"

# application-specific settings
source "$ZSHENV_DIR/applications.zsh"
source "$ZSHENV_DIR/credentials.zsh"

# platform-specific settings
source "$ZSHENV_DIR/darwin.zsh"
source "$ZSHENV_DIR/linux.zsh"
source "$ZSHENV_DIR/wsl.zsh"
