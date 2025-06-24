# system configurations
let
  # supported systems with their default configurations
  supportedSystems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
  # system-specific configurations
  systemConfigs = {
    "x86_64-linux" = {
      system = "x86_64-linux";
      homePath = "/home";
      osType = "nixos";
    };
    "aarch64-darwin" = {
      system = "aarch64-darwin";
      homePath = "/Users";
      osType = "darwin";
    };
  };
in
{
  # export configurations
  inherit supportedSystems systemConfigs;
  # helper function to get system config
  getSystemConfig = system: systemConfigs.${system};
  # helper function to get all linux systems
  linuxSystems = builtins.filter (sys: systemConfigs.${sys}.osType == "nixos") supportedSystems;
  # helper function to get all darwin systems
  darwinSystems = builtins.filter (sys: systemConfigs.${sys}.osType == "darwin") supportedSystems;
}
