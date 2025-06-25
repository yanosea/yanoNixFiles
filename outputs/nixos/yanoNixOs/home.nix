# nixos home configuration
{ homePath, username, ... }:
{
  imports = [
    # host specific
    ../../home-manager/hosts/yanoNixOs
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
