{ homePath, username, ... }: {
  imports = [
    # cli
    ../../home/programs/cli
    # develop
    ../../home/programs/develop
    # gui
    ../../home/programs/gui
    # languages
    ../../home/programs/languages
    # nixos specific
    ../../home/os/nixos.nix
  ];
  # wayland
  wayland = { windowManager = { hyprland = { }; }; };
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
