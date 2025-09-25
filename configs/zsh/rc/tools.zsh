#
# external tools initialization
#

# homebrew (macOS)
if [[ "$OS" = "Darwin" ]]; then
	eval $(/opt/homebrew/bin/brew shellenv)
fi
# shell plugin manager
eval "$(sheldon source)"
