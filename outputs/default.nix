# outputs
inputs:
let
  # import lib for constants
  lib = import ../lib inputs;
  inherit (lib) username;
  # apps configurations
  apps = import ./apps inputs;
  # # darwin configurations
  darwin = import ./darwin (inputs // { inherit username; });
  # formatter configurations
  formatter = import ./formatter inputs;
  # home-manager configurations
  home-manager = import ./home-manager (inputs // { inherit username; });
  # nixos configurations
  nixos = import ./nixos (inputs // { inherit username; });
in
{
  # apps configurations
  apps = apps;
  # darwin configurations
  darwin = darwin;
  # formatter configurations
  formatter = formatter;
  # home-manager configurations
  home-manager = home-manager;
  # nixos configurations
  nixos = nixos;
}
