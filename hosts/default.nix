inputs:
let
  mkNixOsSystem = {
    system,
    hostname,
    username,
    modules,
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system modules;
    specialArgs = {
      inherit inputs hostname username;
    };
  };
  mkNixOsWslSystem = {
    system,
    hostname,
    username,
    modules,
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [ inputs.nixos-wsl.nixosModules.wsl ] ++ modules;
    specialArgs = {
      inherit inputs hostname username;
    };
  };
  mkDarwinSystem = {
    system,
    hostname,
    username,
    modules,
  }: inputs.darwin.lib.darwinSystem {
    inherit system modules;
    specialArgs = {
      inherit inputs hostname username;
    };
  };
  mkHomeManagerConfiguration = {
    system,
    username,
    overlays,
    modules,
  }: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [ "electron-25.9.0" ];
      };
    };
    extraSpecialArgs = {
      inherit inputs username;
      pkgs-stable = import inputs.nixpkgs-stable {
        inherit system overlays;
        config = {
          allowUnfree = true;
        };
        modules = modules ++ [{
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
            stateVersion = "24.05";
          };
          programs.home-manager.enable = true;
          programs.git.enable = true;
        }];
      };
    };
  };
in
{
  # nixos
  nixos = {
    # nixos
    yanoNixOs = mkNixOsSystem {
      system = "x86_64-linux";
      hostname = "yanoNixOs";
      username = "yanosea";
      modules = [ ./yanoNixOs ];
    };
    # wsl
    yanoNixOsWsl = mkNixOsWslSystem {
      system = "x86_64-linux";
      hostname = "yanoNixOsWsl";
      username = "yanosea";
      modules = [ ./yanoNixOsWsl ];
    };
  };
  # darwin
  darwin = {
    # darwin
    yanoMac = mkDarwinSystem {
      system = "aarch64-darwin";
      hostname = "yanoMac";
      username = "yanosea";
      modules = [ ./yanoMac ];
    };
  };
  # home-manager
  home-manager = {
    # nixos
    "yanosea@yanoNixOS" = mkHomeManagerConfiguration {
      system = "x86_64-linux";
      username = "yanosea";
      overlays = [ inputs.fenix.overlays.default ];
      modules = [ ./yanoNixOS/home-manager.nix ];
    };
    # nixos(wsl)
    "yanosea@yanoNixOsWsl" = mkHomeManagerConfiguration {
      system = "x86_64-linux";
      username = "yanosea";
      overlays = [ inputs.fenix.overlays.default ];
      modules = [ ./yanoNixOSWsl/home-manager.nix ];
    };
    # darwin
    "yanosea@yanoMac" = mkHomeManagerConfiguration {
      system = "aarch64-darwin";
      username = "yanosea";
      overlays = [ inputs.fenix.overlays.default ];
      modules = [ ./yanoMac/home-manager.nix ];
    };
  };
}
