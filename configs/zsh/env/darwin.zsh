#
# darwin (macOS) specific environment settings
#

if [[ "$OS" = "Darwin" ]]; then
	# homebrew
	export HOMEBREW_NO_INSTALL_FROM_API=1
	# mac model detection
	export MAC_MODEL=$(system_profiler SPHardwareDataType | awk -F': ' '/Model Name/{print $2}')
	# karabiner and goku configuration
	export GOKU_EDN_CONFIG_FILE=$XDG_CONFIG_HOME/karabiner/karabiner.edn
	# development libraries and includes
	export CPATH=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include
	export LIBRARY_PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
	export C_INCLUDE_PATH=$CPATH
	export CPLUS_INCLUDE_PATH=$CPATH
	export CGO_ENABLED=0
fi

