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
    ## rust
    fenix = {
      url = "github:nix-community/fenix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    ## mediaplayer
    mediaplayer = {
      url = "github:nomisreual/mediaplayer";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## quickshell
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
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
    nixosConfigurations = (import ./outputs inputs).nixos;
    # darwin
    darwinConfigurations = (import ./outputs inputs).darwin;
    # home-manager
    homeConfigurations = (import ./outputs inputs).home-manager;
    # formatter
    formatter = (import ./outputs inputs).formatter;
  };
}
