{
  imports = [
    ./fonts.nix
    ./security.nix
    ./sound.nix
  ];
  xdg = {
    portal = {
      enable = true;
    };
  };
}
