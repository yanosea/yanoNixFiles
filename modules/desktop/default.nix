{ pkgs, ... }: {
  imports = [
    ./fcitx5.nix
    ./fonts.nix
    ./security.nix
    ./sound.nix
    ./xremap.nix
  ];
  # programs
  programs = {
    dconf.enable = true;
  };
  # xdg
  xdg = {
    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
      ];
    };
  };
}
