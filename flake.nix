{
  description = "nix configuration of yanosea";
  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    # nixpkgs(darwin)
    nixpkgs-darwin = {
      url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs-darwin";
        };
      };
    };
    # wsl
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = { nixpkgs, darwin, home-manager, nixos-wsl, ... }:
    let
      systems = [ "x86_64-linux" "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      nixosConfigurations = {
        # nixos
        yanoNixOS = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/yanoNixOS
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.yanosea = import ./home/nixos;
            }
          ];
        };
        # nixos(wsl)
        yanoNixOSWsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.wsl
            ./hosts/yanoNixOSWsl
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.yanosea = import ./home/nixos_wsl;
            }
          ];
        };
      };
      # macos
      darwinConfigurations = {
        yanoMac = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/yanoMac
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.yanosea = import ./home/darwin;
            }
          ];
        };
      };
      formatter = forAllSystems (
        system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );
    };
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    eval-cache = true;
    substituters = [
      "https://cache.nixos.org/"
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
