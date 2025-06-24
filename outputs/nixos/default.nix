# nixos configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib)
    mkNixOsSystem
    mkNixOsWslSystem
    ;
  system = "x86_64-linux";
  homePath = "/home";
in
{
  # nixos
  yanoNixOs = mkNixOsSystem {
    hostname = "yanoNixOs";
    inherit username system homePath;
    modules = [ ./yanoNixOs ];
  };
  # nixos (wsl)
  yanoNixOsWsl = mkNixOsWslSystem {
    hostname = "yanoNixOsWsl";
    inherit username system homePath;
    modules = [ ./yanoNixOsWsl ];
  };
}
