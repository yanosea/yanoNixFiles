{
  description = "nix configuration of yanosea";
  inputs = {
    # nixos
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };
    # nixos hardware configurations
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    # nixos(wsl)
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # darwin
    nixpkgs-darwin = {
      url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    };
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # rust toolchain
    fenix = {
      url = "github:nix-community/fenix";
    };
    # xremap
    xremap = {
      url = "github:xremap/nix-flake";
    };
    # hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprsome = {
      url = "github:sopa0/hyprsome";
    };
    # nur
    nekowinston-nur = {
      url = "github:nekowinston/nur";
    };
  };
  outputs =
  inputs:
  let
    allSystems = [
      # linux
      "x86_64-linux"
      # darwin(arm)
      "aarch64-darwin"
    ];
    forAllSystems = inputs.nixpkgs.lib.genAttrs allSystems;
  in
  {
    # pkgs
    packages = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system});
    # nixos
    nixosConfigurations = (import ./hosts inputs).nixos;
    # darwin
    darwinConfigurations = (import ./hosts inputs).darwin;
    # home-manager
    homeConfigurations = (import ./hosts inputs).home-manager;

    devShells = forAllSystems (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        formatters = with pkgs; [
          nixfmt-rfc-style
          rustfmt
          stylua
          taplo
        ];
        scripts = [
          (pkgs.writeScriptBin "update-input" ''
            nix flake lock --override-input "$1" "$2"
          '')
        ];
      in
      {
        default = pkgs.mkShell { packages = ([ pkgs.nh ]) ++ formatters ++ scripts; };
      }
    );

    formatter = forAllSystems (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        formatters = with pkgs; [
          nixfmt-rfc-style
          rustfmt
          stylua
          taplo
        ];
        format = pkgs.writeScriptBin "format" ''
          PATH=$PATH:${pkgs.lib.makeBinPath formatters}
          ${pkgs.treefmt}/bin/treefmt --config-file ${./treefmt.toml}
        '';
      in
      format
    );
  };
}
