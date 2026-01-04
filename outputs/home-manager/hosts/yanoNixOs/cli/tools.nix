# home tools module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      fuseiso
    ];
  };
}
