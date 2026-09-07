# nixos hardware clock module
{ pkgs, ... }:
{
  # services
  services = {
    # the RTC is shared with Windows, so it holds local time. that is what
    # time.hardwareClockInLocalTime (shared-modules/time.nix) declares.
    chrony = {
      enable = true;
      servers = [ "ntp.jst.mfeed.ad.jp" ];
      serverOption = "iburst";
      # rtcfile + rtcautotrim. safe for a local-time RTC: the module only emits
      # rtconutc when hardwareClockInLocalTime is false.
      enableRTCTrimming = true;
      autotrimThreshold = 20;
      # no initstepslew: deprecated upstream, and it ran before DNS was up.
      # the default makestep 0.1 3 covers the first 3 updates.
    };
  };
  # systemd
  systemd = {
    services = {
      # the kernel reads the RTC as UTC, so a local-time RTC starts the system one
      # TZ offset ahead until chrony steps it. hwclock cannot fix it here (acpi-tad
      # emits no tick, so it just times out); sysfs reads fine and date -s parses
      # its argument as local time, which is how the RTC stores it.
      set-system-clock-from-rtc = {
        description = "Set system clock from the local-time RTC";
        wants = [ "local-fs.target" ];
        after = [ "local-fs.target" ];
        before = [
          "sysinit.target"
          "chronyd.service"
        ];
        conflicts = [ "shutdown.target" ];
        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = "/sys/class/rtc/rtc0/time";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "set-system-clock-from-rtc" ''
            set -u
            rtc=/sys/class/rtc/rtc0
            d=$(${pkgs.coreutils}/bin/cat "$rtc/date" 2>/dev/null) || exit 0
            t=$(${pkgs.coreutils}/bin/cat "$rtc/time" 2>/dev/null) || exit 0
            # do not feed a half-read attribute to date -s
            case "$d" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) exit 0 ;; esac
            case "$t" in [0-9][0-9]:[0-9][0-9]:[0-9][0-9]) ;; *) exit 0 ;; esac
            ${pkgs.coreutils}/bin/date -s "$d $t" >/dev/null
          '';
        };
        wantedBy = [ "basic.target" ];
      };
    };
  };
}
