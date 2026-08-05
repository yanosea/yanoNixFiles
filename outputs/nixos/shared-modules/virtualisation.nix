# nixos virtualisation module
{ lib, ... }:
{
  # virtualisation
  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
  # docker-rootless.nix applies `wantedBy = [ "default.target" ]` to every
  # non-root user session (no per-user opt-out), so greetd's "greeter"
  # session also tries to start it and fails with "No subuid ranges found".
  # Disable the global autostart and start it explicitly from the real
  # user's Hyprland session instead (see configs/hypr/hyprland.conf).
  systemd.user.services.docker.wantedBy = lib.mkForce [ ];
}
