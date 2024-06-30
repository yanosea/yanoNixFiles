{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../../home-manager/cli
    ../../home-manager/gui
    ../../home-manager/desktop/hyprland
  ];
  # wayland
  wayland = {
    windowManager = {
      hyprland = {
        settings = {
          monitor = [
            "HDMI-A-1, 1920x1080@60, 0x0, auto"
            "DP-3, 1920x1080@144, 1920x0, auto"
            "DP-2, 1920x1080@60, 3840x0, auto"
          ];
          workspace = [
            "1, monitor:HDMI-A-1"
            "2, monitor:DP-3"
            "3, monitor:DP-2"
            "4, monitor:HDMI-A-1"
            "5, monitor:DP-3"
            "6, monitor:DP-2"
            "7, monitor:HDMI-A-1"
            "8, monitor:DP-3"
            "9, monitor:DP-2"
          ];
          input = {
            follow_mouse = 1;
            kb_layout = "us";
            natural_scroll = yes;
            touchpad = {
              natural_scroll = yes;
            };
          };
        };
      };
    };
  };
  # home
  home = {
    username = "yanosea";
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
    packages = with pkgs; [
      jdk20
      prismlauncher
    ];
  };
  # programs
  programs = {
    home-manager = {
      enable = true;
    };
  };
}
