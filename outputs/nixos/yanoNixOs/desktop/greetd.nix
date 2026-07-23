# nixos desktop greetd module
{ pkgs, username, ... }:
let
  prefsFile = "/var/lib/greetd/preferred-compositor";
  sessionLauncher = pkgs.writeShellScript "greetd-session-launcher" ''
    SESSION=$(cat "${prefsFile}" 2>/dev/null | tr -d '[:space:]')
    case "$SESSION" in
      niri-session|start-hyprland) ;;
      *) SESSION="start-hyprland" ;;
    esac
    exec ${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd "$SESSION"
  '';
in
{
  systemd = {
    tmpfiles = {
      rules = [
        "d /var/lib/greetd 0770 ${username} greeter -"
        "f /var/lib/greetd/preferred-compositor 0660 ${username} greeter - start-hyprland"
      ];
    };
  };

  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${sessionLauncher}";
          user = "greeter";
        };
      };
    };
  };
}
