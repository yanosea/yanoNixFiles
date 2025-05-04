#!/usr/bin/env bash
# yanosea darwin nix env update script
# sync ghq repos
echo -e $'\n\e[33;1msync ghq repos!\e[m'
ghq list | ghq get --update
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
xargs -I arg ghq get arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/ghq/pkglist.txt
# install go packages
echo -e $'\n\e[33;1minstall go packages!\e[m'
xargs -I arg go install arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/go/pkglist.txt
# install brew packages
echo -e $'\n\e[33;1minstall brew packages!\e[m'
xargs -I arg brew install arg <$HOME/ghq/github.com/yanosea/yanoNixFiles/pkglist/brew/pkglist.txt
# update nix
echo -e $'\n\e[33;1mupdate nix!\e[m'
nix-env -u
# apply nix
echo -e $'\n\e[33;1mapply nix darwin!\e[m'
sudo rm -r $HOME/.nix-defexpr && sudo nix-channel --update
cargo make darwin.apply.system
# apply home-manager
echo -e $'\n\e[33;1mapply home-manager!\e[m'
cargo make darwin.apply.home
# done!
echo -e $'\n\e[32;1mupdate complete!\e[m'
