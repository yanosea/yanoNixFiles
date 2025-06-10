inputs:
let
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
          programs = {
            home-manager = {
              enable = true;
            };
          };
        }
      ];
    };
in
{
  # nixos
  nixos = {
    # nixos
    yanoNixOs = mkNixOsSystem {
      homePath = "/home";
      hostname = "yanoNixOs";
      modules = [ ./yanoNixOs ];
      system = "x86_64-linux";
      username = "yanosea";
    };
    # nixos wsl
    yanoNixOsWsl = mkNixOsWslSystem {
      homePath = "/home";
      hostname = "yanoNixOsWsl";
      modules = [ ./yanoNixOsWsl ];
      system = "x86_64-linux";
      username = "yanosea";
    };
  };
  # darwin
  darwin = {
    # mac
    yanoMac = mkDarwinSystem {
      homePath = "/Users";
      hostname = "yanoMac";
      modules = [ ./yanoMac ];
      system = "aarch64-darwin";
      username = "yanosea";
    };
    # macbook
    yanoMacBook = mkDarwinSystem {
      homePath = "/Users";
      hostname = "yanoMacBook";
      modules = [ ./yanoMacBook ];
      system = "aarch64-darwin";
      username = "yanosea";
    };
  };
  # home-manager
  home-manager = {
    # nixos
    "yanosea@yanoNixOs" = mkHomeManagerConfiguration {
      homePath = "/home";
      modules = [ ./yanoNixOs/home.nix ];
      overlays = import ../overlays inputs;
      system = "x86_64-linux";
      username = "yanosea";
    };
    # nixos wsl
    "yanosea@yanoNixOsWsl" = mkHomeManagerConfiguration {
      homePath = "/home";
      modules = [ ./yanoNixOsWsl/home.nix ];
      overlays = import ../overlays inputs;
      system = "x86_64-linux";
      username = "yanosea";
    };
    # mac
    "yanosea@yanoMac" = mkHomeManagerConfiguration {
      homePath = "/Users";
      modules = [ ./yanoMac/home.nix ];
      overlays = import ../overlays inputs;
      system = "aarch64-darwin";
      username = "yanosea";
    };
    # macbook
    "yanosea@yanoMacBook" = mkHomeManagerConfiguration {
      homePath = "/Users";
      modules = [ ./yanoMacBook/home.nix ];
      overlays = import ../overlays inputs;
      system = "aarch64-darwin";
      username = "yanosea";
    };
  };
}
