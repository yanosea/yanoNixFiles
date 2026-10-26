# lib
inputs:
let
  # import system and constant configurations
  systems = import ./systems.nix;
  constants = import ./constants.nix;
  # the nixosSystem wiring both linux hosts share; each prepends its host module
  mkNixOsSystemWith =
    hostModule:
    {
      homePath,
      hostname,
      modules,
      system,
      username,
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ hostModule ] ++ modules;
      specialArgs = {
        inherit
          homePath
          hostname
          inputs
          username
          ;
      };
    };
in
{
  # export system and constant configurations
  inherit (systems) supportedSystems getSystemConfig;
  inherit (constants) username;
  mkNixOsSystem = mkNixOsSystemWith inputs.lanzaboote.nixosModules.lanzaboote;
  mkNixOsWslSystem = mkNixOsSystemWith inputs.nixos-wsl.nixosModules.wsl;
  mkDarwinSystem =
    {
      homePath,
      hostname,
      modules,
      system,
      username,
    }:
    inputs.darwin.lib.darwinSystem {
      inherit modules system;
      specialArgs = {
        inherit
          homePath
          hostname
          inputs
          username
          ;
      };
    };
  mkHomeManagerConfiguration =
    {
      homePath,
      hostname,
      modules,
      overlays,
      system,
      username,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit overlays system;
        config = {
          allowUnfree = true;
        };
      };
      extraSpecialArgs = {
        inherit
          homePath
          hostname
          inputs
          system
          username
          ;
        # the claude model tier pins, shared by the claude and openclaw configs
        aiModels = import ./ai-models.nix;
        # the third-party agent packages every agent cli shares
        agentPackages = import ./agent-packages.nix { inherit (inputs.nixpkgs) lib; };
        # status messages shared with the apps
        messages = import ./messages.nix;
      };
      modules = modules ++ [
        inputs.sops-nix.homeManagerModules.sops
        {
          home = {
            inherit username;
            homeDirectory = "${homePath}/${username}";
          };
        }
      ];
    };
}
