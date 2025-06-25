# shared modules for NixOS
{
  imports = [
    ./i18n.nix
    ./networking.nix
    ./nix.nix
    ./security.nix
    ./shell.nix
    ./system-packages.nix
    ./time.nix
    ./virtualisation.nix
  ];
}
