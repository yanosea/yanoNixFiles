#
# .zshenv
#

[[ -f ./.zshrc ]] && . ./.zshrc

# edited by yanosea

# os
export OS=$(uname)
if [[ "$OS" = "Linux" ]]; then
	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
	fi
fi
# xdg config
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
# editor
if command -v lvim >/dev/null 2>&1; then
	export VISUAL="lvim"
	export EDITOR="lvim"
elif command -v nvim >/dev/null 2>&1; then
	export VISUAL="nvim"
	export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
	export VISUAL="vim"
	export EDITOR="vim"
else
	export VISUAL="vi"
	export EDITOR="vi"
fi
# browser
if [[ "$OS" = "Linux" ]] && [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	export BROWSER="vivaldi"
fi
# term
export TERM=xterm-256color
# histfiles
## less
export LESSHISTFILE=$XDG_STATE_HOME/less/.lesshst
## node
export NODE_REPL_HISTORY=$XDG_STATE_HOME/node/.node_repl_history
# homebrew
export HOMEBREW_NO_INSTALL_FROM_API=1
# google drive
export GOOGLE_DRIVE=$HOME/google_drive
# path
## local
export PATH=$PATH:$HOME/.local/bin
## zsh functions
### common
for file in $XDG_CONFIG_HOME/zsh/functions/*; do
	if [ -f "$file" ]; then
		source "$file"
	fi
done
### wsl
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
	export PATH=$PATH:/mnt/c/Windows
	export PATH=$PATH:/mnt/c/Windows/System32
	for file in $XDG_CONFIG_HOME/zsh/functions_win/*; do
		source "$file"
	done
fi
## go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
## cargo
export PATH=$PATH:$HOME/.cargo/bin
## pnpm
export PNPM_HOME=$XDG_DATA_HOME/pnpm
## python
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PATH:$PYENV_ROOT/bin
## ghq
export GHQ_ROOT="$HOME"/ghq
# credentials
## openai
export OPENAI_API_KEY=$(cat $XDG_DATA_HOME/credentials/openapi/OPENAI_API_KEY)
## spotify
export SPOTIFY_ID=$(cat $XDG_DATA_HOME/credentials/spotify/SPOTIFY_ID)
export SPOTIFY_SECRET=$(cat $XDG_DATA_HOME/credentials/spotify/SPOTIFY_SECRET)
export SPOTIFY_REDIRECT_URI=$(cat $XDG_DATA_HOME/credentials/spotify/SPOTIFY_REDIRECT_URI)
export SPOTIFY_REFRESH_TOKEN=$(cat $XDG_DATA_HOME/credentials/spotify/SPOTIFY_REFRESH_TOKEN)
## trello
export TRELLO_USER=$(cat $XDG_DATA_HOME/credentials/trello/TRELLO_USER)
export TRELLO_KEY=$(cat $XDG_DATA_HOME/credentials/trello/TRELLO_KEY)
export TRELLO_TOKEN=$(cat $XDG_DATA_HOME/credentials/trello/TRELLO_TOKEN)
# starship
export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
# wakatime
export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
# darwin
if [[ "$OS" = "Darwin" ]]; then
	# model
	export MAC_MODEL=$(system_profiler SPHardwareDataType | awk -F': ' '/Model Name/{print $2}')
	# karabiner and goku
	export GOKU_EDN_CONFIG_FILE=$XDG_CONFIG_HOME/karabiner/karabiner.edn
	# libs
	export CPATH=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include
	export LIBRARY_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
	export C_INCLUDE_PATH=$CPATH
	export CPLUS_INCLUDE_PATH=$CPATH
	export CGO_ENABLED=0
fi
