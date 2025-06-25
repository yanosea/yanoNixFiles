#
# external tools initialization
#

# homebrew (macOS)
if [[ "$OS" = "Darwin" ]]; then
	eval $(/opt/homebrew/bin/brew shellenv)
fi
# shell plugin manager
eval "$(sheldon source)"
# directory jumping
eval "$(zoxide init zsh)"
# python version manager
eval "$(pyenv init -)"
# prompt theme
eval "$(starship init zsh)"
# fuzzy finder
source <(fzf --zsh)

