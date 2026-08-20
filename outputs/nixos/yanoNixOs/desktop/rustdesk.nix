# nixos desktop rustdesk module
{ pkgs, ... }:
{
  # networking
  networking = {
    firewall = {
      # direct IP access (`direct-access-port` in RustDesk2.toml). without this the
      # id/relay route still works, since that one only ever dials outward.
      allowedTCPPorts = [ 21118 ];
    };
  };
  # mirrors upstream res/rustdesk.service
  systemd = {
    services = {
      rustdesk = {
        description = "RustDesk";
        requires = [ "network.target" ];
        after = [ "systemd-user-sessions.service" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          PULSE_LATENCY_MSEC = "60";
          PIPEWIRE_LATENCY = "1024/48000";
        };
        # `--service` shells out for all of these to spawn `--server` in the login
        # session, and none are on a unit's default PATH. getent is what corrects the
        # root HOME that `sudo -E` passes down; without it the server silently ends up
        # with an empty one. also needs `rustdesk --tray` from hyprland.conf.
        path = [
          # the setuid sudo, not the raw package
          "/run/wrappers"
          pkgs.gawk
          pkgs.getent
          pkgs.procps
        ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
          ExecStop = ''${pkgs.procps}/bin/pkill -f "rustdesk --"'';
          PIDFile = "/run/rustdesk.pid";
          KillMode = "mixed";
          TimeoutStopSec = 30;
          User = "root";
          LimitNOFILE = 100000;
        };
      };
    };
  };
}
