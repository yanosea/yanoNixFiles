# nixos desktop modules
{
  imports = [
    ./bluetooth.nix
    ./camera-priority.nix
    ./environment.nix
    ./fuse.nix
    ./game.nix
    ./graphics-tools.nix
    ./hwclock.nix
    ./hyprland.nix
    ./niri.nix
    ./media.nix
    ./security.nix
    ./sound.nix
    ./xdg-mime.nix
    ./xserver.nix
  ];
}
