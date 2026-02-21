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
      qimgv
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
            ExecStart = lib.mkForce "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
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
