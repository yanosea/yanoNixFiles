# home media module
{ lib, pkgs, ... }:
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
            TimeoutStopSec = lib.mkForce 5;
          };
        };
      };
    };
  };
}
