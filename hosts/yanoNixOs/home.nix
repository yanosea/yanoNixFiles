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
  # wayland
  wayland = {
    windowManager = {
      hyprland = { };
    };
  };
  # home
  home = {
    enableNixpkgsReleaseCheck = true;
    homeDirectory = "${homePath}/${username}";
    sessionVariables = {
      ZDOTDIR = "${homePath}/${username}/.config/zsh";
    };
    # this is not latest but ok because this option have to set the first version of Nix configured for me
    stateVersion = "24.05";
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
