# nixos desktop niri module
{ pkgs, ... }:
{
  # programs
  programs = {
    dconf = {
      enable = true;
    };
    niri = {
      enable = true;
      package = pkgs.niri;
    };
  };
  # xdg
  xdg = {
    portal = {
      config = {
        niri = {
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
    };
  };
}
