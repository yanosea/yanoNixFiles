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
    ## determinate (nix-darwin module for Determinate Nix)
    ## no nixpkgs follows: upstream advises against it (FlakeHub Cache misses)
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
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
    ## deja-vu (source; nixpkgs `deja` is an unrelated zsh tool)
    deja-vu = {
      url = "github:vshulcz/deja-vu/v0.22.1";
      flake = false;
    };
    ## llm-agents (agentsview, grok, opencode)
    ## no nixpkgs follows: it would miss the numtide binary cache
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
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
    ## treefmt-nix
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    ## yomiyasu (the skill every agent cli reads)
    yomiyasu = {
      url = "github:nanaism/yomiyasu";
      flake = false;
    };
    ## agent skills linked for the clis that cannot install them as plugins,
    ## at the release tags the pinned plugins ship
    agent-skills = {
      url = "github:addyosmani/agent-skills/0.6.13";
      flake = false;
    };
    caveman = {
      url = "github:JuliusBrussee/caveman/v4.0.1";
      flake = false;
    };
    ponytail = {
      url = "github:DietrichGebert/ponytail/v5.3.2";
      flake = false;
    };
    superpowers = {
      url = "github:obra/superpowers/v7.0.0";
      flake = false;
    };
    taste-skill = {
      url = "github:Leonxlnx/taste-skill/v2.1.2";
      flake = false;
    };
    ## imozuru (a research skill every agent cli reads)
    imozuru = {
      url = "github:MaryCache/imozuru";
      flake = false;
    };
    ## rea (the reverse-engineering skill, at the tag of the pinned mcp server)
    rea = {
      url = "github:morluto/rea/rea-agents-6.7.0";
      flake = false;
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
