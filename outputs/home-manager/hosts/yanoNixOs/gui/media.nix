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
            ExecStart = lib.mkForce "${pkgs.easyeffects}/bin/easyeffects --service-mode";
            TimeoutStartSec = lib.mkForce 30;
            TimeoutStopSec = lib.mkForce 5;
            Type = lib.mkForce "simple";
          };
          Unit = {
            After = lib.mkForce [ "pipewire.service" ];
          };
        };
      };
    };
  };
}
