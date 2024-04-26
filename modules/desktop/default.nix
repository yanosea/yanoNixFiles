{ pkgs, ... }: {
  imports = [ ./fonts.nix ./security.nix ./sound.nix ];
  # programs
  programs = { dconf = { enable = true; }; };
  # xdg
  xdg = { portal = { enable = true; }; };
}
