{ pkgs, username, ... }: {
  imports = [
    ../../home-manager/os/darwin
  ];
  # home
  home = {
    username = "yanosea";
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";
  };
  # programs
  programs = {
    home-manager = {
      enable = true;
    };
  };
}
