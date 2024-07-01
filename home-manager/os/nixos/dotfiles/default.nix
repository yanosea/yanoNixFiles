{ pkgs, ... }: {
  imports = [
    ./dolphin
    ./fcitx5
    ./gnome-control-center
    ./hypr
    ./kde.org
    ./swaync
    ./waybar
  ];
  home.packages = with pkgs; [
    cron
    discord
    discord-ptb
    fuseiso
    localsend
    parsec-bin
    rclone
    remmina
    sheldon
    vivaldi
    xfce.thunar
  ];
}
