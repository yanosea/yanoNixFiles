{ homePath, username, ... }:
{
  imports = [
    # cli
    ../../home/programs/cli
    # gui
    ../../home/programs/gui
    # languages
    ../../home/programs/languages
    # nixos specific
    ../../home/os/nixos.nix
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
