{ homePath, username, ... }:
{
  imports = [
    # cli
    ../../home-manager/modules/cli
    # gui
    ../../home-manager/modules/gui
    # languages
    ../../home-manager/modules/languages
    # nixos specific
    ../../home-manager/os/nixos
    # config
    ../../../config
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
    zsh = {
      enable = true;
    };
  };
}
