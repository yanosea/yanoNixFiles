# home python module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      pyenv
      python314
      python314Packages.pydbus
      python314Packages.psutil
      uv
    ];
  };
}
