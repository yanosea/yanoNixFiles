{ pkgs, ... }:
{
  # gtk
  gtk = {
    enable = true;
    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Blue-Dark";
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
  # home
  home = {
    packages = with pkgs; [ dconf ];
    pointerCursor = {
      gtk = {
        enable = true;
      };
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 12;
    };
  };
}
