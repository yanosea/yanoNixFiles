# home media module
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # home
  home = {
    packages = with pkgs; [
      easyeffects
      evince
      qimgv
      mpv
      spotify
      totem
    ];
  };
}
