# home google-drive module
{
  config,
  pkgs,
  username,
  ...
}:
let
  # rclone bisync script
  rcloneBisyncScript = pkgs.writeShellScript "rclone-bisync-google-drive" ''
    #!/bin/bash
    set -euo pipefail
    echo "starting rclone bisync..."
    # prepare sync directory
    echo "preparing sync directory..."
    ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/google_drive"
    echo "sync directory ready"
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
    # check for first-time sync or resync needed
    BISYNC_WORKDIR="${config.xdg.cacheHome}/rclone/bisync"
    if [ ! -d "$BISYNC_WORKDIR" ] || ! ls "$BISYNC_WORKDIR"/${username}_*.path1.lst >/dev/null 2>&1; then
      echo "first time sync or resync needed, performing initial sync..."
      ${pkgs.rclone}/bin/rclone bisync "${username}:/" "${config.home.homeDirectory}/google_drive" \
        --config "${config.xdg.configHome}/rclone/rclone.conf" \
        --resync \
        --create-empty-src-dirs \
        --compare size,modtime \
        --drive-acknowledge-abuse \
        --drive-skip-gdocs \
        --drive-skip-shortcuts \
        --drive-skip-dangling-shortcuts \
        --metadata \
        --fix-case \
        --resilient \
        --recover \
        --max-lock 2m \
        --transfers 32 \
        --checkers 64 \
        --tpslimit 20 \
        --tpslimit-burst 40 \
        --drive-chunk-size 256M \
        --fast-list \
        --buffer-size 512M \
        --use-mmap \
        --multi-thread-streams 8 \
        --multi-thread-cutoff 50M \
        --log-level INFO \
        --log-file "${config.xdg.cacheHome}/rclone-bisync.log"
    else
      echo "performing regular bisync..."
      ${pkgs.rclone}/bin/rclone bisync "${username}:/" "${config.home.homeDirectory}/google_drive" \
        --config "${config.xdg.configHome}/rclone/rclone.conf" \
        --create-empty-src-dirs \
        --compare size,modtime \
        --drive-acknowledge-abuse \
        --drive-skip-gdocs \
        --drive-skip-shortcuts \
        --drive-skip-dangling-shortcuts \
        --metadata \
        --fix-case \
        --resilient \
        --recover \
        --max-lock 2m \
        --track-renames \
        --transfers 32 \
        --checkers 64 \
        --tpslimit 20 \
        --tpslimit-burst 40 \
        --drive-chunk-size 256M \
        --fast-list \
        --buffer-size 512M \
        --use-mmap \
        --multi-thread-streams 8 \
        --multi-thread-cutoff 50M \
        --log-level INFO \
        --log-file "${config.xdg.cacheHome}/rclone-bisync.log"
    fi
    echo "bisync completed"
  '';
  # cleanup script for bisync
  rcloneCleanupScript = pkgs.writeShellScript "rclone-cleanup-google-drive" ''
    #!/bin/bash
    echo "cleaning up rclone bisync..."
    # kill any existing rclone processes for bisync
    ${pkgs.procps}/bin/pkill -f "rclone bisync ${username}:" || true
    echo "cleanup completed"
  '';
in
{
  # home
  home = {
    packages = with pkgs; [
      rclone
    ];
  };
  # use systemd user service and timer for periodic bisync
  systemd = {
    user = {
      services = {
        rclone-google-drive-bisync = {
          Unit = {
            Description = "rclone Google Drive bisync service";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
            # Prevent timer from killing manual execution
            RefuseManualStart = false;
            RefuseManualStop = false;
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${rcloneBisyncScript}";
            ExecStopPost = "${rcloneCleanupScript}";
            StandardOutput = "journal";
            StandardError = "journal";
            TimeoutStartSec = "infinity";
          };
        };
      };
      timers = {
        rclone-google-drive-bisync = {
          Unit = {
            Description = "rclone Google Drive bisync timer";
            After = [ "network-online.target" ];
          };
          Timer = {
            OnBootSec = "30s";
            OnUnitInactiveSec = "15min";
            Persistent = true;
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      };
    };
  };
}
