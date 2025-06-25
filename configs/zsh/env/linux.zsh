#
# linux (non-WSL) specific environment settings
#

# browser preference
if [[ "$OS" = "Linux" ]] && [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	export BROWSER="vivaldi"
fi
