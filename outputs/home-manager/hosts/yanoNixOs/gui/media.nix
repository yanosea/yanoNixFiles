# home media module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      evince
      feh
      imv
      mediaplayer
      mpv
      spotify
      totem
    ];
  };
  # services
  services = {
    easyeffects = {
      enable = true;
    };
  };
  # programs
  programs = {
    obs-studio = {
      enable = true;
    };
  };
}
