#!/usr/bin/env bash
# yanosea nixos wsl install packages script
# confirm install
if gum confirm "Do you install packages for NixOS WSL?"; then
	# install new packages
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# apply nix
	echo -e $'\n\e[33;1mapply nixos wsl!\e[m'
	cargo make wsl.apply.system
	# apply home-manager
	echo -e $'\n\e[33;1mapply home-manager!\e[m'
	cargo make wsl.apply.home
	# done!
	echo -e $'\n\e[32;1minstall complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1minstall cancelled...\e[m'
fi
