#!/etc/profiles/per-user/yanosea/bin/zsh
# yanosea nixos env initialize script
# confirm initialize
if gum confirm "Do you initialize nixos env?"; then
	# make necessary directories
	mkdir -p ~/.local/bin
	mkdir -p $XDG_DATA_HOME/skk
	mkdir -p $XDG_STATE_HOME/skk
	mkdir -p $XDG_STATE_HOME/yankring
	mkdir -p $XDG_STATE_HOME/zsh
	# make necessary symbolic links
	ln -s ~/ghq/github.com/yanosea/yanoNixFiles/scripts/util/installGitEmojiPrefixTemplate ~/.local/bin/installGitEmojiPrefixTemplate
	ln -s /mnt/google_drive/yanosea ~/google_drive
	ln -s ~/google_drive/credentials $XDG_DATA_HOME/credentials
	ln -s $XDG_DATA_HOME/credentials/github-copilot/hosts.json $XDG_CONFIG_HOME/github-copilot/hosts.json
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install gh extensions
	echo -e $'\n\e[33;1minstall gh extensions!\e[m'
	gh auth login
	xargs -I arg gh extension install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/gh/pkglist.txt
	# install cargo packages
	echo -e $'\n\e[33;1minstall cargo packages!\e[m'
	rustup toolchain install stable
	rustup default stable
	rustup component add rust-src
	xargs -I arg cargo install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/cargo/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# install skk dictionary
	echo -e $'\n\e[33;1minstall skk jisyos!\e[m'
	jisyo d
	# install vimplug
	echo -e $'\n\e[33;1minstall vimplug!\e[m'
	ln -s $XDG_CONFIG_HOME/vim ~/.vim
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	# initialize nixos
	echo -e $'\n\e[33;1minitialize nixos!\e[m'
	cargo make yanoNixOS:apply
	# done!
	echo -e $'\n\e[32;1minitializing complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1minitialize cancelled...\e[m'
fi
