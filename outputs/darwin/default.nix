# darwin configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) mkDarwinSystem;
  system = "aarch64-darwin";
  homePath = "/Users";
in
{
  # mac
  yanoMac = mkDarwinSystem {
    hostname = "yanoMac";
    inherit username system homePath;
    modules = [ ./yanoMac ];
  };
  # macbook
  yanoMacBook = mkDarwinSystem {
    hostname = "yanoMacBook";
    inherit username system homePath;
    modules = [ ./yanoMacBook ];
  };
}
