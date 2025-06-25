#
# WSL specific environment settings
#

# zsh functions
# wsl-specific functions and paths
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
	export PATH=$PATH:/mnt/c/Windows
	export PATH=$PATH:/mnt/c/Windows/System32
	for file in $XDG_CONFIG_HOME/zsh/functions_win/*; do
		source "$file"
	done
fi
