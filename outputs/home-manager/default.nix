# home-manager configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) mkHomeManagerConfiguration;
  overlays = import ../../overlays inputs;
in
{
  # nixos
  "${username}@yanoNixOs" = mkHomeManagerConfiguration {
    modules = [
      ./shared-modules
      ../nixos/yanoNixOs/home.nix
    ];
    inherit username overlays;
    system = "x86_64-linux";
    homePath = "/home";
  };
  # nixos (wsl)
  "${username}@yanoNixOsWsl" = mkHomeManagerConfiguration {
    modules = [
      ./shared-modules
      ../nixos/yanoNixOsWsl/home.nix
    ];
    inherit username overlays;
    system = "x86_64-linux";
    homePath = "/home";
  };
  # mac
  "${username}@yanoMac" = mkHomeManagerConfiguration {
    modules = [
      ./shared-modules
      ../darwin/yanoMac/home.nix
    ];
    inherit username overlays;
    system = "aarch64-darwin";
    homePath = "/Users";
  };
  # macbook
  "${username}@yanoMacBook" = mkHomeManagerConfiguration {
    modules = [
      ./shared-modules
      ../darwin/yanoMacBook/home.nix
    ];
    inherit username overlays;
    system = "aarch64-darwin";
    homePath = "/Users";
  };
}
