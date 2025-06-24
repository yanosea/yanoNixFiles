# darwin configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) mkDarwinSystem getSystemConfig;
  systemConfig = getSystemConfig "aarch64-darwin";
  inherit (systemConfig) system homePath;
in
{
  # mac configuration
  yanoMac = mkDarwinSystem {
    hostname = "yanoMac";
    inherit username system homePath;
    modules = [
      ./shared-modules
      ./yanoMac
    ];
  };
  # macbook configuration
  yanoMacBook = mkDarwinSystem {
    hostname = "yanoMacBook";
    inherit username system homePath;
    modules = [
      ./shared-modules
      ./yanoMacBook
    ];
  };
}
