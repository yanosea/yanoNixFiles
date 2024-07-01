#!/etc/profiles/per-user/yanosea/bin/zsh
# yanosea darwin nix env initialize script
# confirm initialize
if gum confirm "Do you initialize darwin nix env?"; then
	# make necessary directories
	mkdir -p ~/.local/bin
	mkdir -p $XDG_DATA_HOME/skk
	mkdir -p $XDG_STATE_HOME/skk
	mkdir -p $XDG_STATE_HOME/yankring
	mkdir -p $XDG_STATE_HOME/zsh
	# make necessary symbolic links
	ln -s ~/ghq/github.com/yanosea/yanoNixFiles/scripts/util/installGitEmojiPrefixTemplate ~/.local/bin/installGitEmojiPrefixTemplate
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# install homebrew
	echo -e $'\n\e[33;1minstall homebrew!\e[m'
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	# install brew pkgs
	echo -e $'\n\e[33;1minstall homebrew packages!\e[m'
	xargs brew install <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
	# install skk dictionary
	echo -e $'\n\e[33;1minstall skk jisyos!\e[m'
	jisyo d
	# install vimplug
	echo -e $'\n\e[33;1minstall vimplug!\e[m'
	ln -s $XDG_CONFIG_HOME/vim ~/.vim
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	# init skhd and yabai
	skhd --start-service
	yabai --start-service
	# notify creatting google drive symbolic link
	echo -e $'\n\e[31;1mYou heve to create google drive symbolic link!\e[m'
	echo -e $'\e[33;1mln -s GOOGLE_DRIVE_PATH ~/google_drive\e[m'
	# notify creatting credentials symbolic link
	echo -e $'\n\e[31;1mYou heve to create credentials symbolic link!\e[m'
	echo -e $'\e[33;1mln -s ~/google_drive/credentials $XDG_DATA_HOME/credentials\e[m'
	echo -e $'\e[33;1mln -s $XDG_DATA_HOME/credentials/github-copilot/hosts.json $XDG_CONFIG_HOME/github-copilot/hosts.json\e[m'
	# done!
	echo -e $'\n\e[32;1minitializing complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1minitialize cancelled...\e[m'
fi
