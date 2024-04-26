{ pkgs, ... }: {
  imports = [
    ./AquaSKK
    ./hammerspoon
    ./karabiner
    ./raycast
    ./skhd
    ./sonic-pi.net
    ./yabai
  ];
  home.packages = with pkgs; [
    darwin.CF
  ];
}
