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
    };
    "aarch64-darwin" = {
      system = "aarch64-darwin";
      homePath = "/Users";
    };
  };
in
{
  # export configurations
  inherit supportedSystems;
  # helper function to get system config
  getSystemConfig = system: systemConfigs.${system};
}
