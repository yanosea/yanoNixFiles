{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # util
      btop
      duf
      dust
      htop
      ncdu
      systemctl-tui
    ];
  };
}
