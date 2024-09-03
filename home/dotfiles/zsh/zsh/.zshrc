#
# .zshrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PROMPT='[%n@%m %~]$ '

# edited by yanosea

# zellij
if command -v zellij &>/dev/null; then
	if [ -z "$INSIDE_ZELLIJ" ]; then
		export INSIDE_ZELLIJ=1
		exec zellij
	fi
fi
# homebrew
if [[ "$OS" = "Darwin" ]]; then
	eval $(/opt/homebrew/bin/brew shellenv)
fi
# sheldon
eval "$(sheldon source)"
# zoxide
eval "$(zoxide init zsh)"
# python
eval "$(pyenv init -)"
# starship
eval "$(starship init zsh)"
# fzf
source <(fzf --zsh)
# alias
alias cat="$(which bat)"
alias dot="cd $HOME/ghq/github.com/yanosea/yanoNixFiles"
alias gbp='git branch --merged | grep -v "\* $(git rev-parse --abbrev-ref HEAD)" | grep -v "^\s*$" | xargs -r git branch -d'
alias gsf='git switch $(git branch -l | fzf | tr -d "* ")'
alias ls="$(which lsd)"
alias nvimdiff="$(which nvim) -d"
alias lg="lazygit"
alias lvimdiff="$(which lvim) -d"
alias reboot="sudo systemctl reboot"
alias rm="$(which trash)"
if [[ "$OS" = "Darwin" ]]; then
	alias rrm="/bin/rm"
elif [[ "$OS" = "Linux" ]]; then
	alias rrm="/run/current-system/sw/bin/rm"
fi
alias shutdown="sudo systemctl poweroff"
alias st="systemctl-tui"
alias tree="$(which eza) --tree"
alias trl="trello-tui -board yanoBoard"
alias zmv="noglob zmv -W"
# make state directory
if [[ ! -d "$XDG_STATE_HOME/zsh" ]]; then
	mkdir -p "$XDG_STATE_HOME/zsh"
fi
# history
HISTFILE=$XDG_STATE_HOME/zsh/.zhistory
HISTSIZE=1000
SAVEHIST=10000
# zshopt
## easy cd
setopt auto_cd
## choose completion with tab
setopt auto_menu
## add slash
setopt auto_param_slash
## completion in typing
setopt complete_in_word
## beep off
setopt no_beep
## correct typo
setopt correct
## enable glob
setopt extendedglob nomatch
## glob with dot
setopt globdots
## ignore history start with space
setopt hist_ignore_space
## disable C-d
setopt IGNORE_EOF
## show file type
setopt list_types
## completion with equal
setopt magic_equal_subst
## add slash
setopt mark_dirs
## notify background job status
setopt notify
## japanese file name
setopt print_eight_bit
## write history immediately
setopt inc_append_history
## append history
setopt append_history
## save time stamp in history
setopt extended_history
## ignore command start with space
setopt hist_ignore_space
# when to append history
setopt inc_append_history_time
## choose completion with arrow keys
zstyle ":completion:*:default" menu select=2
## upper case or lowercase
zstyle ":completion:*" matcher-list "m:{a-z}={A-Z}"
## zmv
autoload -Uz zmv
# AA
show_random_aa
