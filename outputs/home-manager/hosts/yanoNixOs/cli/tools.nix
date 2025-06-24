# home tools module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      clipse
      fuseiso
    ];
  };
}
