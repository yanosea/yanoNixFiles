# home-manager configurations
{ username, ... }@inputs:
let
  lib = import ../../lib inputs;
  inherit (lib) mkHomeManagerConfiguration getSystemConfig;
  overlays = import ../../overlays inputs;

  # host configurations mapping
  hostConfigs = {
    yanoNixOs = {
      system = "x86_64-linux";
      osType = "nixos";
    };
    yanoNixOsWsl = {
      system = "x86_64-linux";
      osType = "nixos";
    };
    yanoMac = {
      system = "aarch64-darwin";
      osType = "darwin";
    };
    yanoMacBook = {
      system = "aarch64-darwin";
      osType = "darwin";
    };
  };

  # helper function to create home-manager configuration
  mkHostHomeConfig =
    hostname: hostConfig:
    let
      systemConfig = getSystemConfig hostConfig.system;
    in
    mkHomeManagerConfiguration {
      modules = [
        ./shared-modules
        ../${hostConfig.osType}/${hostname}/home.nix
      ];
      inherit username overlays;
      inherit (systemConfig) system homePath;
    };
in
# generate configurations for all hosts
builtins.listToAttrs (
  builtins.attrValues (
    builtins.mapAttrs (hostname: hostConfig: {
      name = "${username}@${hostname}";
      value = mkHostHomeConfig hostname hostConfig;
    }) hostConfigs
  )
)
