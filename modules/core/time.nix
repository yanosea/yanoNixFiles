{ pkgs, ... }:
{
  # services
  services = {
    chrony = {
      enable = true;
      servers = [ "ntp.jst.mfeed.ad.jp" ];
      serverOption = "iburst";
      enableRTCTrimming = true;
      autotrimThreshold = 20;
      initstepslew.enabled = true;
    };
  };
  # systemd
  systemd = {
    services = {
      chrony-first-sync = {
        description = "Synchronize system clock on startup";
        after = [
          "network-online.target"
          "chronyd.service"
        ];
        bindsTo = [ "chronyd.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [
          "multi-user.target"
          "time-sync.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
          ExecStart = "${pkgs.chrony}/bin/chronyc makestep";
          SuccessExitStatus = "0 1";
        };
      };
      fix-timezone-early = {
        description = "Fix timezone before chrony starts";
        before = [ "chronyd.service" ];
        after = [ "set-hwclock-early.service" ];
        unitConfig = {
          DefaultDependencies = false;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date -s \"$(${pkgs.coreutils}/bin/date)\"'";
        };
        wantedBy = [ "basic.target" ];
      };
      set-hwclock-early = {
        description = "Set hardware clock early in boot process";
        wants = [ "local-fs.target" ];
        after = [ "local-fs.target" ];
        before = [
          "sysinit.target"
          "chronyd.service"
        ];
        conflicts = [ "shutdown.target" ];
        unitConfig = {
          DefaultDependencies = false;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.util-linux}/bin/hwclock --hctosys --localtime";
        };
        wantedBy = [ "basic.target" ];
      };
    };
  };
  # time
  time = {
    hardwareClockInLocalTime = true;
    timeZone = "Asia/Tokyo";
  };
}
