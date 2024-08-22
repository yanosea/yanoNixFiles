#!/usr/bin/env bash
# yanosea nix darwin env initialize script
# initialize nix darwin
echo -e $'\n\e[33;1minitialize nix darwin!\e[m'
sudo rm -r $HOME/.nix-defexpr && sudo nix-channel --update
cargo make darwin.apply.system
# apply home-manager
echo -e $'\n\e[33;1minitialize home!\e[m'
cargo make darwin.apply.home
source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zshrc
# make necessary directories
echo -e $'\n\e[33;1mmake necessary directories!\e[m'
mkdir -p $HOME/.local/bin
mkdir -p $XDG_DATA_HOME/skk
mkdir -p $XDG_STATE_HOME/skk
mkdir -p $XDG_STATE_HOME/yankring
mkdir -p $XDG_STATE_HOME/zsh
mkdir -p $XDG_CONFIG_HOME/wakatime
# make necessary symbolic links
echo -e $'\n\e[33;1mmake necessary symbolic links!\e[m'
ln -s $HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/util/installGitEmojiPrefixTemplate $HOME/.local/bin/installGitEmojiPrefixTemplate
# clone ghq repos
echo -e $'\n\e[33;1mclone ghq packages!\e[m'
xargs -I arg ghq get arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
# install go packages
echo -e $'\n\e[33;1minstall go packages!\e[m'
xargs -I arg go install arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
# install brew pkgs
echo -e $'\n\e[33;1minstall homebrew packages!\e[m'
xargs brew install <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
# install skk dictionary
echo -e $'\n\e[33;1minstall skk jisyos!\e[m'
jisyo d
# install vimplug
echo -e $'\n\e[33;1minstall vimplug!\e[m'
ln -s $XDG_CONFIG_HOME/vim $HOME/.vim
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install era
echo -e $'\n\e[33;1minstall era!\e[m'
cd $HOME/ghq/github.com/kyoheiu/era
make install
mv era $HOME/.local/bin/
cd $HOME/ghq/github.com/yanosea/yanoNixFiles
# init sketchybar
echo -e $'\n\e[33;1minit sketchybar!\e[m'
cd ~/.config/sketchybar/helpers
make
cd $HOME/ghq/github.com/yanosea/yanoNixFiles
# # install sketchybar plugins
echo -e $'\n\e[33;1minstall sketchybar font!\e[m'
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.4/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
# init services
echo -e $'\n\e[33;1minit services!\e[m'
brew services start sketchybar
brew services start borders
skhd --start-service
yabai --start-service
# notify creatting google drive symbolic link
echo -e $'\n\e[31;1mYou have to create google drive symbolic link!\e[m'
echo -e $'\e[33;1mln -s GOOGLE_DRIVE_PATH $HOME/google_drive\e[m'
# notify creatting credentials symbolic link
echo -e $'\n\e[31;1mYou have to create credentials symbolic link!\e[m'
echo -e $'\e[33;1mln -s $HOME/google_drive/credentials $XDG_DATA_HOME/credentials\e[m'
echo -e $'\e[33;1mln -s $XDG_DATA_HOME/credentials/github-copilot/hosts.json $XDG_CONFIG_HOME/github-copilot/hosts.json\e[m'
echo -e $'\e[33;1mln -s $XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $XDG_CONFIG_HOME/wakatime/.wakatime.cfg\e[m'
# done!
echo -e $'\n\e[32;1minitializing done!\e[m'
