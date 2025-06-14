{ pkgs, username, ... }:
{
  # environment
  environment = {
    systemPackages = with pkgs; [
      fuse3
      rclone
    ];
  };
  # programs
  programs = {
    fuse = {
      userAllowOther = true;
    };
  };
  # systemd
  systemd = {
    services = {
      # rclone
      rclone = {
        enable = true;
        description = "rclone Google Drive mount service";
        after = [
          "network-online.target"
          "time-sync.target"
        ];
        wants = [
          "network-online.target"
          "time-sync.target"
        ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.rclone}/bin/rclone mount ${username}: /mnt/google_drive/${username} --allow-other --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M --drive-chunk-size 64M --config /home/${username}/.config/rclone/rclone.conf";
          ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /mnt/google_drive/${username} && ${pkgs.coreutils}/bin/chown ${username}:users /mnt/google_drive/${username}'";
          ExecStop = "${pkgs.util-linux}/bin/umount -l /mnt/google_drive/${username}";
          Restart = "on-failure";
          RestartSec = "10s";
          Type = "simple";
          User = "root";
          Group = "root";
        };
      };
    };
    tmpfiles = {
      rules = [
        "d /mnt/google_drive/${username} 0755 ${username} users -"
      ];
    };
  };
}
