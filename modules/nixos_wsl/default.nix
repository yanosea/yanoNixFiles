{ pkgs, ... }: {
  # wsl
  wsl = {
    enable = true;
    defaultUser = "yanosea";
    wslConf = {
      automount = {
        root = "/mnt";
      };
      interop = {
        appendWindowsPath = false;
        enabled = true;
      };
      network = {
        generateHosts = false;
      };
    };
  };
  # boot
  boot = {
    loader = {
      grub = {
        device = "nodev";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
  # networking
  networking = {
    networkmanager = {
      enable = true;
    };
    firewall = {
      enable = true;
    };
  };
  # security
  security = {
    rtkit = {
      enable = true;
    };
    sudo = {
      wheelNeedsPassword = true;
    };
  };
  # time
  time = {
    timeZone = "Asia/Tokyo";
    hardwareClockInLocalTime = true;
  };
  # language
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
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
      dates = "weekly";
      options = "--delete-older-than 1w";
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
  # system
  system = {
    stateVersion = "24.05";
  };
}
