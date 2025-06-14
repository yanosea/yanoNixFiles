{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      evince
      mediaplayer
      spotify
      totem
    ];
  };
  # programs
  programs = {
    easyeffects = {
      enable = true;
    };
    obs-studio = {
      enable = true;
    };
  };
}
