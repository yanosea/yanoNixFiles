{ pkgs, ... }:
{
  imports = [
    ../config
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
