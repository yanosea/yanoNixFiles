#
# path environment settings
#

# local bin path
export PATH=$PATH:$HOME/.local/bin
# zsh functions
## common functions
for file in $XDG_CONFIG_HOME/zsh/functions/*; do
	if [ -f "$file" ]; then
		source "$file"
	fi
done
## ghq
export GHQ_ROOT="$HOME"/ghq
