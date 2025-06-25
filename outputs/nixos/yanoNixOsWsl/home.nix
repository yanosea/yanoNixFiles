# nixos (wsl) home configuration
{
  config,
  homePath,
  username,
  ...
}:
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
      ZDOTDIR = "${config.xdg.configHome}/zsh";
    };
    stateVersion = "24.05"; # DO NOT CHANGE
    username = username;
  };
}
