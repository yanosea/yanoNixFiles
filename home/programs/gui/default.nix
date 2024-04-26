{ pkgs, inputs, ... }: {
  imports = [ ./desktop.nix ./game.nix ./gtk.nix ./media.nix ./xdg.nix ];
}
