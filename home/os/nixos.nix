{ pkgs, ... }:
{
  imports = [
    ../dotfiles/dolphin
    ../dotfiles/dunst
    ../dotfiles/hypr
    ../dotfiles/waybar
    ../dotfiles/wofi
  ];
  home = {
    packages = with pkgs; [
      clipse
      fuseiso
      rclone
      wineWowPackages.staging
      winetricks
    ];
  };
}
