#!/run/current-system/sw/bin/zsh
# yanosea darwin nix install packages script
# confirm install
if gum confirm "Do you install packages for darwin?"; then
	# install new packages
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# install brew packages
	echo -e $'\n\e[33;1minstall brew packages!\e[m'
	xargs -I arg brew install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
	# apply nix
	echo -e $'\n\e[33;1mapply nix!\e[m'
	cargo make yanoMac:apply
	# done!
	echo -e $'\n\e[32;1minstall complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1minitialize cancelled...\e[m'
fi
