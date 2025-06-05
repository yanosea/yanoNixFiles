{ pkgs, ... }:
{
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
  # home
  home = {
    packages = with pkgs; [
      xcode-install
    ];
  };
  # homebrew
  homebrew = {
    enable = true;
    brews = [
      "candid82/brew/joker"
      "felixkratz/formulae/borders"
      "felixkratz/formulae/sketchybar"
      "koekeishiya/formulae/skhd"
      "koekeishiya/formulae/yabai"
      "nowplaying-cli"
      "switchaudio-osx"
      "yqrashawn/goku/goku"
    ];
    casks = [
      "ableton-live-suite"
      "android-file-transfer"
      "appcleaner"
      "aquaskk"
      "arc"
      "bitwarden"
      "blackhole-16ch"
      "blender"
      "chrome-remote-desktop-host"
      "contexts"
      "coteditor"
      "daisydisk"
      "easyfind"
      "font-sf-mono"
      "font-sf-pro"
      "github-beta"
      "github@beta"
      "google-drive"
      "hammerspoon"
      "hiddenbar"
      "karabiner-elements"
      "launchpad-manager"
      "libreoffice"
      "libreoffice-language-pack"
      "microsoft-auto-update"
      "microsoft-teams"
      "omnidisksweeper"
      "onyx"
      "processing"
      "raycast"
      "sf-symbols"
      "sonic-pi"
      "splashtop-personal"
      "splice"
      "spotify"
      "supercollider"
      "the-unarchiver"
      "touchdesigner"
      "visual-studio-code"
    ];
  };
}
