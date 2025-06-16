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
            # css, html
            prettier = {
              enable = true;
              includes = [
                "*.css"
                "*.html"
              ];
            };
            # json
            jsonfmt = {
              enable = true;
              includes = [ "*.json" ];
            };
            # kdl
            kdlfmt = {
              enable = true;
              includes = [ "*.kdl" ];
            };
            # lua
            stylua = {
              enable = true;
            };
            # markdown
            mdformat = {
              enable = true;
              includes = [ "*.md" ];
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
            # yaml
            yamlfmt = {
              enable = true;
              includes = [
                "*.yaml"
                "*.yml"
              ];
            };
          };
        }).config.build.wrapper
      );
  };
}
