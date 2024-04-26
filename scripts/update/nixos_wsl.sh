#!/etc/profiles/per-user/yanosea/bin/zsh
# yanosea nixos wsl env update script
# confirm update
if gum confirm "Do you update nixos env?"; then
	# sync ghq repos
	echo -e $'\n\e[33;1msync ghq repos!\e[m'
	ghq list | ghq get --update
	# update gh extensions
	echo -e $'\n\e[33;1mupdate gh extensions!\e[m'
	gh extension upgrade --all
	# update cargo packages
	echo -e $'\n\e[33;1mupdate cargo packages!\e[m'
	cargo install-update -a
	# update go packages
	echo -e $'\n\e[33;1mupdate go packages!\e[m'
	gup update
	# update zsh plugins
	echo -e $'\n\e[33;1mupdate zsh plugins!\e[m'
	sheldon lock --update
	# install new packages
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install gh extensions
	echo -e $'\n\e[33;1minstall gh extensions!\e[m'
	xargs -I arg gh extension install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/gh/pkglist.txt
	# install cargo packages
	echo -e $'\n\e[33;1minstall cargo packages!\e[m'
	xargs -I arg cargo install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/cargo/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# update nix
	echo -e $'\n\e[33;1mupdate nix!\e[m'
	nix-env -u
	cargo make yanoNixOSWsl:apply
	# done!
	echo -e $'\n\e[32;1mupdate complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1mupdate cancelled...\e[m'
fi
