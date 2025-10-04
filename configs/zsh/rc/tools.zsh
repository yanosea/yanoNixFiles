#
# external tools initialization
#

# homebrew (macOS)
if [[ "$OS" = "Darwin" ]]; then
	eval $(/opt/homebrew/bin/brew shellenv)
fi
# direnv
eval "$(direnv hook zsh)"
# shell plugin manager
eval "$(sheldon source)"
