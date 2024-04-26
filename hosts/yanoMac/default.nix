{ hostname, homePath, pkgs, username, ... }: {
  # fonts
  fonts = { packages = with pkgs; [ plemoljp-nf noto-fonts-emoji ]; };
  # networking
  networking = { hostName = hostname; };
  # nix
  nix = {
    envVars = { ZDOTDIR = "$HOME/.config/zsh"; };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
      user = "root";
    };
    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://helix.cachix.org"
        "https://nekowinston.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "nekowinston.cachix.org-1:lucpmaO+JwtoZj16HCO1p1fOv68s/RL1gumpVzRHRDs="
      ];
      trusted-users = [ "root" "@wheel" username ];
    };
    useDaemon = true;
  };
  # nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };
  # programs
  programs = { zsh = { enable = true; }; };
  # services
  services = { nix-daemon = { enable = true; }; };
  # users
  users = {
    users = {
      "${username}" = {
        home = "/${homePath}/${username}";
        shell = pkgs.zsh;
      };
    };
  };
}
