{ inputs, pkgs, ... }:
{
  # home
  home.packages = (with pkgs; [
    gnome.totem
    gnome.evince
    spotify
  ]);
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
