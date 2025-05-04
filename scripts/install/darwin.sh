#!/usr/bin/env bash
# yanosea darwin nix install packages script
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
# apply nix
echo -e $'\n\e[33;1mapply nix darwin!\e[m'
sudo rm -r $HOME/.nix-defexpr && sudo nix-channel --update
cargo make darwin.apply.system
# apply home-manager
echo -e $'\n\e[33;1mapply home-manager!\e[m'
cargo make darwin.apply.home
# done!
echo -e $'\n\e[32;1minstall complete!\e[m'
