{ pkgs, ... }:
{
  # home
  home = {
    packages = (
      with pkgs;
      [
        mediaplayer
        evince
        spotify
        totem
      ]
    );
  };
  # programs
  programs = {
    ncspot = {
      enable = true;
    };
    obs-studio = {
      enable = true;
    };
  };
  # services
  services = {
    easyeffects = {
      enable = true;
    };
  };
}
