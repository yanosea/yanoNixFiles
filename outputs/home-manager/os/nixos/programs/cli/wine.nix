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
