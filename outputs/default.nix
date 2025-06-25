# outputs
inputs:
let
  # import lib for constants
  lib = import ../lib inputs;
  inherit (lib) username;
  # os configurations
  nixos = import ./nixos (inputs // { inherit username; });
  darwin = import ./darwin (inputs // { inherit username; });
  # home-manager configurations
  home-manager = import ./home-manager (inputs // { inherit username; });
  # formatter configurations
  formatter = import ./formatter inputs;
in
{
  # nixos configurations
  nixos = nixos;
  # darwin configurations
  darwin = darwin;
  # home-manager configurations
  home-manager = home-manager;
  # formatter configurations
  formatter = formatter;
}
