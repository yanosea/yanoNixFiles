{ pkgs, ... }: {
  # dconf
  dconf = {
    settings = {
      "org/gnome/desktop/background" = {
        picture-uri-dark =
          "file://${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
      };
      "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    };
  };
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
      gtk = { enable = true; };
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 14;
    };
  };
}
