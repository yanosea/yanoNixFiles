# nixos (wsl) home configuration
{ homePath, username, ... }:
{
  imports = [
    # nixos specific
    ../../home-manager/os/nixos
    # configs (dotfiles)
    ../../../configs
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
