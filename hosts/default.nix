inputs:
let
  mkNixOsSystem = { homePath, hostname, modules, system, username, }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules system;
      specialArgs = { inherit homePath hostname inputs username; };
    };
  mkNixOsWslSystem = { homePath, hostname, modules, system, username, }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ inputs.nixos-wsl.nixosModules.wsl ] ++ modules;
      specialArgs = { inherit homePath hostname inputs username; };
    };
  mkDarwinSystem = { homePath, hostname, modules, system, username, }:
    inputs.darwin.lib.darwinSystem {
      inherit modules system;
      specialArgs = { inherit homePath hostname inputs username; };
    };
  mkHomeManagerConfiguration =
    { homePath, modules, overlays, system, username, }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit overlays system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "electron-25.9.0" ];
        };
      };
      extraSpecialArgs = {
        inherit homePath inputs username;
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit overlays system;
          config = { allowUnfree = true; };
        };
      };
      modules = modules ++ [{
        home = {
          inherit username;
          homeDirectory = "${homePath}/${username}";
          stateVersion = "24.05";
        };
        programs = {
          home-manager = { enable = true; };
          git = { enable = true; };
        };
      }];
    };
in {
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
    # darwin
    yanoMac = mkDarwinSystem {
      homePath = "/home";
      hostname = "yanoMac";
      modules = [ ./yanoMac ];
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
      overlays = [ inputs.fenix.overlays.default ];
      system = "x86_64-linux";
      username = "yanosea";
    };
    # nixos wsl
    "yanosea@yanoNixOsWsl" = mkHomeManagerConfiguration {
      homePath = "/home";
      modules = [ ./yanoNixOsWsl/home.nix ];
      overlays = [ inputs.fenix.overlays.default ];
      system = "x86_64-linux";
      username = "yanosea";
    };
    # darwin
    "yanosea@yanoMac" = mkHomeManagerConfiguration {
      homePath = "/Users";
      modules = [ ./yanoMac/home.nix ];
      overlays = [ inputs.fenix.overlays.default ];
      system = "aarch64-darwin";
      username = "yanosea";
    };
  };
}
