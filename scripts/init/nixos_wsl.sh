#!/run/current-system/sw/bin/zsh
# yanosea nixos wsl env initialize script
# confirm initialize
if gum confirm "Do you initialize nixos wsl env?"; then
	# make necessary directories
	mkdir -p ~/.local/bin
	mkdir -p ~/.local/share/skk
	mkdir -p ~/.local/state/skk
	mkdir -p ~/.local/state/yankring
	mkdir -p ~/.local/state/zsh
	# make necessary symbolic links
	ln -s ~/ghq/github.com/yanosea/yanoNixFiles/scripts/util/installGitEmojiPrefixTemplate ~/.local/bin/installGitEmojiPrefixTemplate
	# clone ghq repos
	echo -e $'\n\e[33;1mclone ghq packages!\e[m'
	xargs -I arg ghq get arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
	# install go packages
	echo -e $'\n\e[33;1minstall go packages!\e[m'
	xargs -I arg go install arg <~/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
	# install skk dictionary
	echo -e $'\n\e[33;1minstall skk jisyos!\e[m'
	jisyo d
	# install vimplug
	echo -e $'\n\e[33;1minstall vimplug!\e[m'
	ln -s ~/.config/vim ~/.vim
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	# notify creatting google drive symbolic link
	echo -e $'\n\e[31;1mYou heve to create google drive symbolic link!\e[m'
	echo -e $'\e[33;1mln -s GOOGLE_DRIVE_PATH ~/google_drive\e[m'
	# notify creatting credentials symbolic link
	echo -e $'\n\e[31;1mYou heve to create credentials symbolic link!\e[m'
	echo -e $'\e[33;1mln -s ~/google_drive/credentials $XDG_DATA_HOME/credentials\e[m'
	echo -e $'\e[33;1mln -s $XDG_DATA_HOME/credentials/github-copilot/hosts.json $XDG_CONFIG_HOME/github-copilot/hosts.json\e[m'
	# notify creatting windows home symbolic link
	echo -e $'\n\e[31;1mYou heve to windows home symbolic link!\e[m'
	echo -e $'\e[33;1mln -s WINDOWS_HOME_PATH ~/windows_home/\e[m'
	# notify creatting win32yank symbolic link
	echo -e $'\n\e[31;1mYou heve to create win32yank symbolic link!\e[m'
	echo -e $'\e[33;1mln -s WINDOWS_WIN32YANK_PATH ~/.local/bin/win32yank.exe\e[m'
	# done!
	echo -e $'\n\e[32;1minitializing complete!\e[m'
else
	# initialize cancelled
	echo -e $'\n\e[31;1minitialize cancelled...\e[m'
fi
