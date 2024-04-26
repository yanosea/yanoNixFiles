#!/usr/bin/env bash
# yanosea nixos env initialize script
# initialize nixos
echo -e $'\n\e[33;1minitialize nixos!\e[m'
cargo make nix.apply.system
# apply home-manager
echo -e $'\n\e[33;1minitialize home!\e[m'
cargo make nix.apply.home
source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zshrc
# make necessary directories
echo -e $'\n\e[33;1make necessary directories!\e[m'
mkdir -p $HOME/.local/bin
mkdir -p $XDG_DATA_HOME/skk
mkdir -p $XDG_STATE_HOME/skk
mkdir -p $XDG_STATE_HOME/yankring
mkdir -p $XDG_STATE_HOME/zsh
mkdir -p $XDG_CONFIG_HOME/wakatime
# initialize rclone
echo -e $'\n\e[33;1initialize rclone!\e[m'
sudo mkdir -p /mnt/google_drive/yanosea
sudo rclone config
# make necessary symbolic links
echo -e $'\n\e[33;1make necessary symbolic links!\e[m'
sudo ln -s /root/.config/rclone/rclone.conf /.rclone.conf
ln -s $HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/util/ime $HOME/.local/bin/ime
ln -s $HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/util/installGitEmojiPrefixTemplate $HOME/.local/bin/installGitEmojiPrefixTemplate
ln -s /mnt/google_drive/yanosea $HOME/google_drive
ln -s $HOME/google_drive/credentials $XDG_DATA_HOME/credentials
ln -s $XDG_DATA_HOME/credentials/github-copilot/hosts.json $XDG_CONFIG_HOME/github-copilot/hosts.json
ln -s $XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $XDG_CONFIG_HOME/wakatime/.wakatime.cfg
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
ln -s $XDG_CONFIG_HOME/vim $HOME/.vim
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install era
cd $HOME/ghq/github.com/kyoheiu/era
make install
mv era $HOME/.local/bin/
cd $HOME/ghq/github.com/yanosea/yanoNixFiles
# done!
echo -e $'\n\e[32;1minitializing done!\e[m'
