{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      clipse
      fuseiso
      rclone
      systemctl-tui
    ];
  };
}
