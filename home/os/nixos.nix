{ pkgs, ... }: {
  imports = [
    ../dotfiles/dolphin
    ../dotfiles/dunst
    ../dotfiles/hypr
    ../dotfiles/waybar
    ../dotfiles/wofi
  ];
  home = {
    packages = with pkgs; [
      # cli
      clipse
      cron
      fuseiso
      rclone
      # gui
      dolphin
      remmina
      vivaldi
      # jokeey
      bsdgames
    ];
  };
}
