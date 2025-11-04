# nixos desktop niri module
{ pkgs, ... }:
{
  # environment
  environment = {
    systemPackages = with pkgs; [
      nautilus
    ];
  };
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
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
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
