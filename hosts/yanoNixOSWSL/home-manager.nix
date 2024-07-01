{ pkgs, username, ... }: {
  imports = [
    ../../home-manager/os/nixos_wsl
  ];
  # home
  home = {
    username = "yanosea";
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };
  # programs
  programs = {
    home-manager = {
      enable = true;
    };
  };
}
