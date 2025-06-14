{ pkgs, ... }:
{
  # time
  time = {
    hardwareClockInLocalTime = true;
    timeZone = "Asia/Tokyo";
  };
  # services
  services.chrony = {
    enable = true;
    servers = [
      "0.pool.ntp.org"
      "1.pool.ntp.org"
      "2.pool.ntp.org"
      "3.pool.ntp.org"
    ];
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
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
          ExecStart = "${pkgs.chrony}/bin/chronyc makestep";
          SuccessExitStatus = "0 1";
        };
      };
    };
  };
}
