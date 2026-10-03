# darwin nix module
{ inputs, username, ... }:
{
  imports = [
    inputs.determinate.darwinModules.default
  ];
  # determinate nix (writes /etc/nix/nix.custom.conf)
  determinateNix = {
    enable = true;
    customSettings = {
      accept-flake-config = true;
      extra-substituters = [
        "https://cache.nixos.org"
        "https://cache.numtide.com"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [
        "root"
        "@wheel"
        username
      ];
    };
  };
  # nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };
}
