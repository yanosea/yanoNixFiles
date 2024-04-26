{
  description = "nix configuration of yanosea";
  inputs = {
    # nixpkgs
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    nixpkgs-stable = { url = "github:nixos/nixpkgs/nixos-24.05"; };
    # nixos hardware
    nixos-hardware = { url = "github:NixOS/nixos-hardware/master"; };
    # nixos wsl
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = { nixpkgs = { follows = "nixpkgs"; }; };
    };
    # darwin
    nixpkgs-darwin = { url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin"; };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = { nixpkgs = { follows = "nixpkgs"; }; };
    };
    # rust toolchain
    fenix = { url = "github:nix-community/fenix"; };
    # xremap
    xremap = { url = "github:xremap/nix-flake"; };
    # hyprland
    hyprland = { url = "github:hyprwm/Hyprland"; };
    # nur
    nekowinston-nur = { url = "github:nekowinston/nur"; };
  };
  outputs = inputs:
    let
      allSystems = [
        # linux
        "x86_64-linux"
        # darwin (arm)
        "aarch64-darwin"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs allSystems;
    in {
      # nixos
      nixosConfigurations = (import ./hosts inputs).nixos;
      # darwin
      darwinConfigurations = (import ./hosts inputs).darwin;
      # home-manager
      homeConfigurations = (import ./hosts inputs).home-manager;
    };
}
