{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      rclone
    ];
  };
  # systemd user services
  systemd.user.services = {
    rclone-google-drive = {
      Unit = {
        Description = "rclone Google Drive mount service";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/google_drive";
        ExecStart = "${pkgs.rclone}/bin/rclone mount yanosea: %h/google_drive --allow-other --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M --drive-chunk-size 64M --config %h/.config/rclone/rclone.conf -v";
        ExecStop = "${pkgs.util-linux}/bin/umount %h/google_drive";
        Restart = "on-failure";
        RestartSec = "15s";
        KillMode = "mixed";
        KillSignal = "SIGINT";
        TimeoutStopSec = "15s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
