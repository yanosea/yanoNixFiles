{ pkgs, inputs, ... }: {
  imports = [
    ./gtk.nix
    ./media.nix
    ./xdg.nix
  ];
}
