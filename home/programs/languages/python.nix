{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      pyenv
      python313
      python313Packages.pydbus
      python313Packages.psutil
    ];
  };
}
