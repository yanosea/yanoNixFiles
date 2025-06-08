{
  imports = [
    ./environment.nix
    ./fonts.nix
    ./security.nix
    ./sound.nix
    ./xserver.nix
  ];
  xdg = {
    portal = {
      enable = true;
    };
  };
}
