{ homePath, username, ... }:
{
  imports = [
    # cli
    ../../home/programs/cli
    # gui (xdg-utils)
    ../../home/programs/gui/xdg.nix
    # languages
    ../../home/programs/languages
    # nixos wsl specific
    ../../home/os/nixos_wsl.nix
  ];
  # home
  home = {
    enableNixpkgsReleaseCheck = true;
    homeDirectory = "${homePath}/${username}";
    sessionVariables = {
      ZDOTDIR = "${homePath}/${username}/.config/zsh";
    };
    stateVersion = "24.05"; # DO NOT CHANGE
    username = username;
  };
  # programs
  programs = {
    home-manager = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
  };
}
