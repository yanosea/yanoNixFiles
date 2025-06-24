# home wine module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      wineWowPackages.staging
      winetricks
    ];
  };
}
