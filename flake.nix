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
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## darwin
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## home-manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## rust
    fenix = {
      url = "github:nix-community/fenix/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # packages
    ## claude-code
    claude-code = {
      url = "github:sadjow/claude-code-nix/main";
    };
    ## jj-starship
    jj-starship = {
      url = "github:dmmulroy/jj-starship/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## treefmt-nix
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## wrangler
    wrangler = {
      url = "github:emrldnix/wrangler/master";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = inputs: {
    # apps
    apps = (import ./outputs inputs).apps;
    # darwin
    darwinConfigurations = (import ./outputs inputs).darwin;
    # formatter
    formatter = (import ./outputs inputs).formatter;
    # home-manager
    homeConfigurations = (import ./outputs inputs).home-manager;
    # nixos
    nixosConfigurations = (import ./outputs inputs).nixos;
  };
}
