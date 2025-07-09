#
# zellij configuration and auto-attach
#

# auto-attach to zellij session on interactive shell startup
# only if we're in a terminal and not already in zellij
if [[ -o interactive ]] && [[ -z "$ZELLIJ" ]] && [[ -n "$TERM" ]] && [[ "$TERM" != "dumb" ]]; then
	# check if zellij is available
	if command -v zellij &>/dev/null; then
		# check for active sessions first
		active_sessions=$(zellij list-sessions 2>/dev/null | grep -v "EXITED")
		if [[ -n "$active_sessions" ]]; then
			# connect to the most recent active session
			session_name=$(echo "$active_sessions" | tail -1 | sed 's/\x1b\[[0-9;]*m//g' | cut -d' ' -f1)
			exec zellij attach "$session_name"
		fi

		# check for EXITED sessions to resurrect
		exited_sessions=$(zellij list-sessions 2>/dev/null | grep "EXITED")
		if [[ -n "$exited_sessions" ]]; then
			# connect to the most recent EXITED session (resurrect it)
			session_name=$(echo "$exited_sessions" | tail -1 | sed 's/\x1b\[[0-9;]*m//g' | cut -d' ' -f1)
			exec zellij attach "$session_name"
		fi

		# no sessions exist, create new
		exec zellij
	fi
fi

