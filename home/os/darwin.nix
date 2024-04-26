{ pkgs, ... }: {
  imports = [
    ../dotfiles/AquaSKK
    ../dotfiles/borders
    ../dotfiles/hammerspoon
    ../dotfiles/karabiner
    ../dotfiles/raycast
    ../dotfiles/sketchybar
    ../dotfiles/skhd
    ../dotfiles/sonic-pi.net
    ../dotfiles/yabai
  ];
  home = {
    packages = with pkgs; [
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.CF
      darwin.xcode
      xcodes
      xcode-install
    ];
  };
}
