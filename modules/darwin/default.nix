{ pkgs, ... }: {
  imports = [ ];
  # time
  time = {
    timeZone = "Asia/Tokyo";
  };
  # services
  services = {
    nix-daemon = {
      enable = true;
    };
  };
  # nix
  nix = {
    envVars = {
      ZDOTDIR = "$HOME/.config/zsh";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "yanosea"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 0; Minute = 0; };
      options = "--delete-older-than 1w";
      user = "root";
    };
  };
  # nixpkgs
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  # environment
  environment = {
    systemPackages = with pkgs; [
      cargo-make
      gcc
      git
      openssl
      openssl.dev
      pkg-config
      zsh
    ];
    extraInit = ''
      export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib
      export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    '';
  };
  # programs
  programs = {
    zsh = {
      enable = true;
    };
  };
  # font
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      plemoljp
      plemoljp-nf
      plemoljp-hs
    ];
  };
}
