# mac home configuration
{ homePath, username, ... }:
{
  imports = [
    # darwin specific
    ../../home-manager/os/darwin
    # config (dotfiles)
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
}
