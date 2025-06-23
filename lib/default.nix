# lib
inputs: {
  mkNixOsSystem =
    {
      homePath,
      hostname,
      modules,
      system,
      username,
    }:
    inputs.nixpkgs.lib.nixosSystem {
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
  mkNixOsWslSystem =
    {
      homePath,
      hostname,
      modules,
      system,
      username,
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ inputs.nixos-wsl.nixosModules.wsl ] ++ modules;
      specialArgs = {
        inherit
          homePath
          hostname
          inputs
          username
          ;
      };
    };
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
        inherit homePath inputs username;
      };
      modules = modules ++ [
        {
          home = {
            inherit username;
            homeDirectory = "${homePath}/${username}";
          };
        }
      ];
    };
}
