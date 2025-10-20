# nixos desktop modules
{
  imports = [
    ./bluetooth.nix
    ./environment.nix
    ./fuse.nix
    ./game.nix
    ./graphics-tools.nix
    ./hwclock.nix
    ./hyprland.nix
    ./security.nix
    ./sound.nix
    ./xdg-mime.nix
    ./xserver.nix
  ];
}
