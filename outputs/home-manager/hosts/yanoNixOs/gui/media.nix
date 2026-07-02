# home media module
{ pkgs, ... }:
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
