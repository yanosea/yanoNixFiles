{ homePath, username, ... }:
{
  imports = [
    # cli
    ../../home-manager/modules/cli
    # languages
    ../../home-manager/modules/languages
    # darwin specific
    ../../home-manager/os/darwin
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
