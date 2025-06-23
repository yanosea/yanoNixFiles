# hosts
inputs:
let
  lib = import ../lib inputs;
  inherit (lib)
    mkNixOsSystem
    mkNixOsWslSystem
    mkDarwinSystem
    mkHomeManagerConfiguration
    ;
  # common settings
  username = "yanosea";
  # host definitions with common settings
  hosts = {
    yanoNixOs = {
      type = "nixos";
      system = "x86_64-linux";
      homePath = "/home";
    };
    yanoNixOsWsl = {
      type = "nixos-wsl";
      system = "x86_64-linux";
      homePath = "/home";
    };
    yanoMac = {
      type = "darwin";
      system = "aarch64-darwin";
      homePath = "/Users";
    };
    yanoMacBook = {
      type = "darwin";
      system = "aarch64-darwin";
      homePath = "/Users";
    };
  };
  # system type to function mapping
  systemFunctions = {
    nixos = mkNixOsSystem;
    nixos-wsl = mkNixOsWslSystem;
    darwin = mkDarwinSystem;
  };
  # generate all configurations
  mkConfigs = hostname: config: {
    system = systemFunctions.${config.type} {
      inherit hostname username;
      modules = [ ./${hostname} ];
      inherit (config) homePath system;
    };
    home = mkHomeManagerConfiguration {
      modules = [ ./${hostname}/home.nix ];
      inherit username;
      overlays = import ../overlays inputs;
      inherit (config) homePath system;
    };
  };
  # all configurations for each host
  allConfigs = builtins.mapAttrs mkConfigs hosts;
  # nixos hosts
  nixosHosts = builtins.filter (h: hosts.${h}.type == "nixos" || hosts.${h}.type == "nixos-wsl") (
    builtins.attrNames hosts
  );
  # darwin hosts
  darwinHosts = builtins.filter (h: hosts.${h}.type == "darwin") (builtins.attrNames hosts);
in
{
  nixos = builtins.listToAttrs (
    map (h: {
      name = h;
      value = allConfigs.${h}.system;
    }) nixosHosts
  );
  darwin = builtins.listToAttrs (
    map (h: {
      name = h;
      value = allConfigs.${h}.system;
    }) darwinHosts
  );
  home-manager = builtins.listToAttrs (
    map (h: {
      name = "${username}@${h}";
      value = allConfigs.${h}.home;
    }) (builtins.attrNames hosts)
  );
}
