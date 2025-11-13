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
  # systemd
  systemd = {
    user = {
      services = {
        easyeffects = {
          Service = {
            TimeoutStopSec = 5;
          };
        };
      };
    };
  };
}
