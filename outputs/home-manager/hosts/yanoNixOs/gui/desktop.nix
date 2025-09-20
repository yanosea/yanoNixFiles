# home desktop module
{ config, pkgs, ... }:
{
  # gtk
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    gtk3 = {
      extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
    };
    gtk4 = {
      extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
    };
  };
  # home
  home = {
    file = {
      "wall_8K.png" = {
        target = "${config.xdg.dataHome}/wallpapers/wall_8K.png";
        source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/hyprwm/Hyprland/778bdf730ff957521cc114d170bc82fc44b8be22/assets/wall_8K.png";
          sha256 = "sha256-VGwyAF73+1eKAFurOMOxi0dn9lbpwD/u5msWy+DS5kg=";
        };
      };
      "wall_anime_8K.png" = {
        target = "${config.xdg.dataHome}/wallpapers/wall_anime_8K.png";
        source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/hyprwm/Hyprland/778bdf730ff957521cc114d170bc82fc44b8be22/assets/wall_anime_8K.png";
          sha256 = "sha256-0H1sbQthf99ybSSli1DfGtQ+sm+MXDaoqJAGs43fx1U=";
        };
      };
      "wall_anime2_8K.png" = {
        target = "${config.xdg.dataHome}/wallpapers/wall_anime2_8K.png";
        source = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/hyprwm/Hyprland/778bdf730ff957521cc114d170bc82fc44b8be22/assets/wall_anime2_8K.png";
          sha256 = "sha256-PNuutAs1WT7vzQSPmvHUIdGcMpXG6Xjzt/pAokiYKTE=";
        };
      };
    };
    packages = (
      with pkgs;
      [
        dconf
        dunst
        gvfs
        hyprcursor
        hypridle
        hyprlock
        hyprpaper
        hyprpicker
        hyprshot
        linux-wallpaperengine
        nemo
        playerctl
        quickshell
        udisks2
        waybar
        wayvnc
        wev
        wf-recorder
        wl-clipboard
        wofi
        wofi-emoji
        yad
      ]
    );
    pointerCursor = {
      gtk = {
        enable = true;
      };
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 12;
    };
  };
  # services
  services = {
    dunst = {
      enable = true;
    };
  };
  # wayland
  wayland = {
    windowManager = {
      hyprland = {
        enable = true;
        # dummy
        settings = {
          env = [ ];
        };
      };
    };
  };
}
