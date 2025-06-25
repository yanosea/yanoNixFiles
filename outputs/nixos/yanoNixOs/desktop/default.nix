# nixos desktop modules
{
  imports = [
    ./bluetooth.nix
    ./environment.nix
    ./fonts.nix
    ./fuse.nix
    ./game.nix
    ./hwclock.nix
    ./hyprland.nix
    ./security.nix
    ./sound.nix
    ./xserver.nix
  ];
}
