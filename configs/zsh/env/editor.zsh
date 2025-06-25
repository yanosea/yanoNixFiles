#
# editor environment settings
#

# editor preference: nvim > vim > vi
if command -v nvim >/dev/null 2>&1; then
	export VISUAL="nvim"
	export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
	export VISUAL="vim"
	export EDITOR="vim"
else
	export VISUAL="vi"
	export EDITOR="vi"
fi