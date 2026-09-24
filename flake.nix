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
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
    ## lanzaboote
    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
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
    ## agy acp server (release archives; hashes live in flake.lock only)
    agy-acp-server-darwin = {
      url = "https://dl.google.com/agy-extensions/releases/macos/agy-acp-server-agy_acp_server_1.1.1-darwin-arm64.zip";
      flake = false;
    };
    agy-acp-server-linux = {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-agy_acp_server_1.1.1-linux-x86_64.zip";
      flake = false;
    };
    ## claude-code
    claude-code = {
      url = "github:sadjow/claude-code-nix/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## openclaw
    openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs = {
        home-manager = {
          follows = "home-manager";
        };
        nix-openclaw-tools = {
          inputs = {
            nixpkgs = {
              follows = "nixpkgs";
            };
          };
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## terminal-browser (release tarballs; hashes live in flake.lock only)
    terminal-browser-darwin = {
      url = "https://github.com/zenbu-labs/terminal-browser/releases/latest/download/terminal-browser-darwin-arm64.tar.gz";
      flake = false;
    };
    terminal-browser-linux = {
      url = "https://github.com/zenbu-labs/terminal-browser/releases/latest/download/terminal-browser-linux-x64.tar.gz";
      flake = false;
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
  };
  outputs =
    inputs:
    let
      # import outputs configurations
      outputs = import ./outputs inputs;
    in
    {
      # apps
      inherit (outputs) apps;
      # darwin
      darwinConfigurations = outputs.darwin;
      # formatter
      inherit (outputs) formatter;
      # home-manager
      homeConfigurations = outputs.home-manager;
      # nixos
      nixosConfigurations = outputs.nixos;
    };
}
