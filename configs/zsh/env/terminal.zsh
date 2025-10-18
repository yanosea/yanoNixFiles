#
# terminal environment settings
#

# terminal configuration
export TERM=xterm-256color
# gpg tty configuration for pinentry
export GPG_TTY=$(tty)
# history file locations for various applications
## less
export LESSHISTFILE=$XDG_STATE_HOME/less/.lesshst
## node
export NODE_REPL_HISTORY=$XDG_STATE_HOME/node/.node_repl_history

