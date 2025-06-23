{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      clipse
      fuseiso
      systemctl-tui
    ];
  };
}
