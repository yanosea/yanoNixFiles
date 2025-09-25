#
# interactive shell settings
#

# check if running interactively
[[ $- != *i* ]] && return
# default prompt (may be overridden by starship)
alias ls='ls --color=auto'
PROMPT='[%n@%m %~]$ '
# create zsh state directory if it doesn't exist
if [[ ! -d "$XDG_STATE_HOME/zsh" ]]; then
	mkdir -p "$XDG_STATE_HOME/zsh"
fi
# history configuration
HISTFILE=$XDG_STATE_HOME/zsh/.zhistory
HISTSIZE=10000
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
unsetopt APPEND_HISTORY         # use share_history instead
setopt HIST_IGNORE_DUPS         # ignore duplicate entries
unsetopt HIST_IGNORE_ALL_DUPS   # keep some duplicates for context
unsetopt HIST_SAVE_NO_DUPS      # save some duplicates
unsetopt HIST_FIND_NO_DUPS      # find duplicates when needed
setopt HIST_IGNORE_SPACE        # ignore entries starting with space
unsetopt HIST_EXPIRE_DUPS_FIRST # don't expire duplicates first
setopt SHARE_HISTORY            # share history between sessions
unsetopt EXTENDED_HISTORY       # don't save timestamps for simplicity
setopt HIST_FCNTL_LOCK          # use fcntl for locking
# completion styling
## choose completion with arrow keys
zstyle ":completion:*:default" menu select=2
## case insensitive completion
zstyle ":completion:*" matcher-list "m:{a-z}={A-Z}"
# autoloads
autoload -Uz zmv
# load custom functions
for file in $XDG_CONFIG_HOME/zsh/functions/*; do
	if [ -f "$file" ]; then
		source "$file"
	fi
done
