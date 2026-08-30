# nixos desktop hyprland module
{ pkgs, ... }:
let
  # upstream reports every ScreenCast stream at desktop (0, 0), so a remote client can
  # only drive the monitor sitting there. drop once upstream reports the real position.
  xdgDesktopPortalHyprland = pkgs.xdg-desktop-portal-hyprland.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./xdg-desktop-portal-hyprland-screencast-position.patch
    ];
  });
in
{
  # programs
  programs = {
    dconf = {
      enable = true;
    };
    hyprland = {
      enable = true;
      portalPackage = xdgDesktopPortalHyprland;
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
      extraPortals = [
        xdgDesktopPortalHyprland
        pkgs.xdg-desktop-portal-gtk
      ];

    };
  };
}
