# nixos desktop hyprland module
{ pkgs, ... }:
{
  # programs
  programs = {
    dconf = {
      enable = true;
    };
    hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland = {
        enable = true;
      };
    };
  };
  # xdg
  xdg = {
    portal = {
      config = {
        common = {
          default = "*";
        };
      };
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];

    };
  };
}
