# darwin configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) mkDarwinSystem;
  system = "aarch64-darwin";
  homePath = "/Users";
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
