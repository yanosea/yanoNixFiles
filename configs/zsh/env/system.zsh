#
# system environment settings
#

# os detection
export OS=$(uname)
if [[ "$OS" = "Linux" ]]; then
	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
	fi
fi
# xdg base directory specification
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

