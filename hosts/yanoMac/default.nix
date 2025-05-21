{
  hostname,
  homePath,
  pkgs,
  username,
  ...
}:
{
  # fonts
  fonts = {
    packages = with pkgs; [
      plemoljp-nf
      noto-fonts-emoji
    ];
  };
  # networking
  networking = {
    hostName = hostname;
  };
  # nix
  nix = {
    enable = true;
    envVars = {
      ZDOTDIR = "$HOME/.config/zsh";
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      accept-flake-config = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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
  # programs
  programs = {
    zsh = {
      enable = true;
    };
  };
  # system
  system = {
    stateVersion = 6;
  };
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
