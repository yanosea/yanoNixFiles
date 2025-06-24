# nixos configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib)
    mkNixOsSystem
    mkNixOsWslSystem
    getSystemConfig
    ;
  systemConfig = getSystemConfig "x86_64-linux";
  inherit (systemConfig) system homePath;
in
{
  # nixos configuration
  yanoNixOs = mkNixOsSystem {
    hostname = "yanoNixOs";
    inherit username system homePath;
    modules = [
      ./shared-modules
      ./yanoNixOs
    ];
  };
  # nixos (wsl) configuration
  yanoNixOsWsl = mkNixOsWslSystem {
    hostname = "yanoNixOsWsl";
    inherit username system homePath;
    modules = [
      ./shared-modules
      ./yanoNixOsWsl
    ];
  };
}
