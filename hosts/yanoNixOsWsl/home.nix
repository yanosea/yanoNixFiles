{ homePath, username, ... }: {
  imports = [
    # cli
    ../../home/programs/cli
    # develop
    ../../home/programs/develop
    # xdg
    ../../home/programs/gui/xdg.nix
    # languages
    ../../home/programs/languages
    # nixos wsl specific
    ../../home/os/nixos_wsl.nix
  ];
  # home
  home = {
    enableNixpkgsReleaseCheck = false;
    homeDirectory = "${homePath}/${username}";
    stateVersion = "24.05";
    username = username;
  };
  # programs
  programs = { home-manager = { enable = true; }; };
}
