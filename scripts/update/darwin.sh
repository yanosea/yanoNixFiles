#!/etc/profiles/per-user/yanosea/bin/zsh
# yanosea darwin nix env update script
# confirm update
if gum confirm "Do you update darwin nix env?"; then
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
	# update brew packages
	echo -e $'\n\e[33;1mupdate brew packages!\e[m'
	brew update
	brew upgrade
	brew cleanup
	brew doctor
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
	# install brew packages
	echo -e $'\n\e[33;1minstall brew packages!\e[m'
	xargs -I arg brew install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
	# update nix
	echo -e $'\n\e[33;1mupdate nix!\e[m'
	nix-env -u
	cargo make yanoMac:apply
	# done!
	echo -e $'\n\e[32;1mupdate complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1minitialize cancelled...\e[m'
fi
