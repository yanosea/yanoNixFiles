# outputs
inputs:
let
  # common username
  username = "yanosea";
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
