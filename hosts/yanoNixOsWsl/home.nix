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
    # this is not latest but ok because this option have to set the first version of Nix configured for me
    stateVersion = "24.05";
    username = username;
  };
  # programs
  programs = {
    home-manager = {
      enable = true;
    };
  };
}
