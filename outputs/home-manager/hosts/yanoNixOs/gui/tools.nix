# home tools module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      bitwarden
      blender
      remmina
    ];
  };
}
