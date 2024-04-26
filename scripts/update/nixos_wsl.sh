#!/usr/bin/env bash
# yanosea nixos wsl env update script
# confirm update
if gum confirm "Do you update nixos env?"; then
	# sync ghq repos
	echo -e $'\n\e[33;1msync ghq repos!\e[m'
	ghq list | ghq get --update
	# update go packages
	echo -e $'\n\e[33;1mupdate go packages!\e[m'
	gup update
	# update zsh plugins
	echo -e $'\n\e[33;1mupdate zsh plugins!\e[m'
	sheldon lock --update
	# install new packages
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# update nix
	echo -e $'\n\e[33;1mupdate nix!\e[m'
	nix-env -u
	# apply nix
	echo -e $'\n\e[33;1mapply nixos!\e[m'
	cargo make wsl.apply.system
	# apply home-manager
	echo -e $'\n\e[33;1mapply home-manager!\e[m'
	cargo make wsl.apply.home
	# done!
	echo -e $'\n\e[32;1mupdate complete!\e[m'
else
	# update cancelled
	echo -e $'\n\e[31;1mupdate cancelled...\e[m'
fi
