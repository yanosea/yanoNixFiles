# home wine module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      wineWow64Packages.staging
      winetricks
    ];
  };
}
