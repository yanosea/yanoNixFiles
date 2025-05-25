{
  description = "nix configuration of yanosea";
  inputs = {
    # nixpkgs
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    # modules
    ## nixos hardware
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    ## nixos wsl
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## darwin
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # packages
    ## hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## treefmt-nix
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = inputs: {
    # nixos
    nixosConfigurations = (import ./hosts inputs).nixos;
    # darwin
    darwinConfigurations = (import ./hosts inputs).darwin;
    # home-manager
    homeConfigurations = (import ./hosts inputs).home-manager;
    # formatter
    formatter =
      with inputs.nixpkgs.lib;
      genAttrs [ "x86_64-linux" "aarch64-darwin" ] (
        system:
        (inputs.treefmt-nix.lib.evalModule inputs.nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            # lua
            stylua = {
              enable = true;
            };
            # nix
            nixfmt = {
              enable = true;
            };
            # rust
            rustfmt = {
              enable = true;
            };
            # shell
            shfmt = {
              enable = true;
            };
            # toml
            taplo = {
              enable = true;
            };
          };
        }).config.build.wrapper
      );
  };
}
