# home tools module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      baobab
      bitwarden-desktop
      blender
      kdePackages.kdenlive
      remmina
    ];
  };
}
