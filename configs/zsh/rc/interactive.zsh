#
# interactive shell settings
#

# check if running interactively
[[ $- != *i* ]] && return
# default prompt (may be overridden by starship)
alias ls='ls --color=auto'
PROMPT='[%n@%m %~]$ '
# zellij auto-start
if command -v zellij &>/dev/null; then
	if [ -z "$INSIDE_ZELLIJ" ]; then
		export INSIDE_ZELLIJ=1
		exec zellij
	fi
fi
# create zsh state directory if it doesn't exist
if [[ ! -d "$XDG_STATE_HOME/zsh" ]]; then
	mkdir -p "$XDG_STATE_HOME/zsh"
fi
# history configuration
HISTFILE=$XDG_STATE_HOME/zsh/.zhistory
HISTSIZE=1000
SAVEHIST=10000
# completion dump file location
export ZSH_COMPDUMP=$XDG_STATE_HOME/zsh/.zcompdump
# zsh options
## navigation
setopt auto_cd          # easy cd
setopt auto_param_slash # add slash
setopt mark_dirs        # add slash to directories
## completion
setopt auto_menu         # choose completion with tab
setopt complete_in_word  # completion in typing
setopt magic_equal_subst # completion with equal
setopt list_types        # show file type
## interface
setopt no_beep         # beep off
setopt correct         # correct typo
setopt print_eight_bit # japanese file name
setopt notify          # notify background job status
setopt IGNORE_EOF      # disable C-d
## globbing
setopt extendedglob nomatch # enable glob
setopt globdots             # glob with dot
## history
setopt inc_append_history      # write history immediately
setopt append_history          # append history
setopt extended_history        # save time stamp in history
setopt hist_ignore_space       # ignore history start with space
setopt inc_append_history_time # when to append history
# completion styling
## choose completion with arrow keys
zstyle ":completion:*:default" menu select=2
## case insensitive completion
zstyle ":completion:*" matcher-list "m:{a-z}={A-Z}"
# autoloads
autoload -Uz zmv
autoload -Uz compinit && compinit -d "$ZSH_COMPDUMP"
# display random ascii art
show_random_aa

