#!/usr/bin/env bash
# yanosea nixos wsl env initialize script
# initialize nixos wsl
echo -e $'\n\e[33;1minitialize nixos wsl!\e[m'
cargo make wsl.apply.system
# apply home-manager
echo -e $'\n\e[33;1minitialize home!\e[m'
cargo make wsl.apply.home
source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zshrc
# make necessary directories
echo -e $'\n\e[33;1make necessary directories!\e[m'
mkdir -p $HOME/.local/bin
mkdir -p $XDG_DATA_HOME/skk
mkdir -p $XDG_STATE_HOME/skk
mkdir -p $XDG_STATE_HOME/zsh
mkdir -p $XDG_CONFIG_HOME/wakatime
# make necessary symbolic links
echo -e $'\n\e[33;1make necessary symbolic links!\e[m'
ln -s $HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/util/installGitEmojiPrefixTemplate $HOME/.local/bin/installGitEmojiPrefixTemplate
# clone ghq repos
echo -e $'\n\e[33;1mclone ghq packages!\e[m'
xargs -I arg ghq get arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
# install go packages
echo -e $'\n\e[33;1minstall go packages!\e[m'
xargs -I arg go install arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
# install skk dictionary
echo -e $'\n\e[33;1minstall skk jisyos!\e[m'
jisyo d
# install vimplug
echo -e $'\n\e[33;1minstall vimplug!\e[m'
ln -s $HOME/.config/vim $HOME/.vim
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install era
cd $HOME/ghq/github.com/kyoheiu/era
make install
mv era $HOME/.local/bin/
cd $HOME/ghq/github.com/yanosea/yanoNixFiles
# notify source zshenv and zshrc
echo -e $'\n\e[31;1mFirst, exec below!\e[m'
echo -e $'\e[33;1msource $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zshrc\e[m'
# notify creatting google drive symbolic link
echo -e $'\n\e[31;1mYou have to create google drive symbolic link!\e[m'
echo -e $'\e[33;1mln -s GOOGLE_DRIVE_PATH $HOME/google_drive\e[m'
# notify creatting credentials symbolic link
echo -e $'\n\e[31;1mYou have to create credentials symbolic link!\e[m'
echo -e $'\e[33;1mln -s $HOME/google_drive/credentials $XDG_DATA_HOME/credentials\e[m'
echo -e $'\e[33;1mln -s $XDG_DATA_HOME/credentials/github-copilot/apps.json $XDG_CONFIG_HOME/github-copilot/apps.json\e[m'
echo -e $'\e[33;1mln -s $XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $XDG_CONFIG_HOME/wakatime/.wakatime.cfg\e[m'
# notify creatting windows home symbolic link
echo -e $'\n\e[31;1mYou have to windows home symbolic link!\e[m'
echo -e $'\e[33;1mln -s WINDOWS_HOME_PATH $HOME/windows_home/\e[m'
# notify creatting win32yank symbolic link
echo -e $'\n\e[31;1mYou have to create win32yank symbolic link!\e[m'
echo -e $'\e[33;1mln -s WINDOWS_WIN32YANK_PATH $HOME/.local/bin/win32yank.exe\e[m'
# done!
echo -e $'\n\e[32;1minitializing done!\e[m'
