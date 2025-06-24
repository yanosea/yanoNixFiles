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
