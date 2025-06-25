# home google-drive module
{
  config,
  pkgs,
  username,
  ...
}:
let
  # rclone mount script
  rcloneMountScript = pkgs.writeShellScript "rclone-mount-google-drive" ''
    #!/bin/bash
    set -euo pipefail
    echo "starting rclone mount script..."
    # wait for FUSE to be properly initialized
    echo "Waiting for FUSE device to be ready..."
    timeout=30
    while [ $timeout -gt 0 ]; do
      if [ -c /dev/fuse ] && [ -w /dev/fuse ]; then
        echo "fuse device is ready"
        break
      fi
      echo "fuse device not ready, waiting... ($timeout seconds left)"
      ${pkgs.coreutils}/bin/sleep 1
      timeout=$((timeout - 1))
    done
    if [ $timeout -le 0 ]; then
      echo "fuse device timeout, proceeding anyway..."
    fi
    # cleanup existing mounts and prepare directory
    echo "preparing mount directory..."
    # attempt to unmount any existing mounts
    ${pkgs.fuse}/bin/fusermount -uz "${config.home.homeDirectory}/google_drive" 2>/dev/null || true
    ${pkgs.util-linux}/bin/umount -l "${config.home.homeDirectory}/google_drive" 2>/dev/null || true
    # wait briefly for unmount to complete
    ${pkgs.coreutils}/bin/sleep 2
    # force remove problematic directory if exists
    ${pkgs.coreutils}/bin/rmdir "${config.home.homeDirectory}/google_drive" 2>/dev/null || ${pkgs.coreutils}/bin/rm -rf "${config.home.homeDirectory}/google_drive" 2>/dev/null || true
    # recreate directory
    ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/google_drive"
    echo "mount directory ready"
    # wait for network with timeout
    echo "waiting for network connectivity..."
    timeout=60
    while [ $timeout -gt 0 ]; do
      if ${pkgs.networkmanager}/bin/nmcli networking connectivity check >/dev/null 2>&1; then
        echo "network connectivity confirmed"
        break
      fi
      echo "network not ready, waiting... ($timeout seconds left)"
      ${pkgs.coreutils}/bin/sleep 2
      timeout=$((timeout - 2))
    done
    if [ $timeout -le 0 ]; then
      echo "network timeout, proceeding anyway..."
    fi
    # verify fusermount is available
    if ! command -v ${pkgs.fuse}/bin/fusermount >/dev/null 2>&1; then
      echo "ERROR: fusermount not available"
      exit 1
    fi
    # start rclone mount
    echo "starting rclone mount..."
    # start rclone mount
    ${pkgs.rclone}/bin/rclone mount ${username}: "${config.home.homeDirectory}/google_drive" \
      --allow-other \
      --vfs-cache-mode full \
      --buffer-size 128M \
      --vfs-read-ahead 512M \
      --drive-chunk-size 64M \
      --config "${config.xdg.configHome}/rclone/rclone.conf" \
      --log-level INFO \
      --log-file "${config.xdg.cacheHome}/rclone-mount.log"
  '';
  # rclone unomnt script
  rcloneUnmountScript = pkgs.writeShellScript "rclone-unmount-google-drive" ''
    #!/bin/bash
    echo "stopping rclone mount..."
    # gracefully unmount
    ${pkgs.fuse}/bin/fusermount -u "${config.home.homeDirectory}/google_drive" 2>/dev/null || true
    # brief wait for unmount
    ${pkgs.coreutils}/bin/sleep 2
    # verify unmount completed
    if ! ${pkgs.util-linux}/bin/mountpoint -q "${config.home.homeDirectory}/google_drive" 2>/dev/null; then
      echo "unmount completed"
    else
      echo "unmount may still be pending"
    fi
  '';
in
{
  # home
  home = {
    packages = with pkgs; [
      rclone
    ];
  };
  # use systemd user service with better handling
  systemd.user.services = {
    rclone-google-drive = {
      Unit = {
        Description = "rclone Google Drive mount service";
        After = [
          "graphical-session.target"
          "network-online.target"
        ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${rcloneMountScript}";
        ExecStop = "${rcloneUnmountScript}";
        Restart = "on-failure";
        RestartSec = "10s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        TimeoutStartSec = "120s";
        TimeoutStopSec = "30s";
        StartLimitBurst = 3;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
