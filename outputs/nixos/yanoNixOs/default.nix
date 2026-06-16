# nixos configuration
{
  config,
  homePath,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # hardware-configuration
    ./hardware-configuration.nix
    # desktop
    ./desktop
  ]
  ++ (with inputs.nixos-hardware.nixosModules; [ common-pc-ssd ]);
  # boot
  boot = {
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
    };
    initrd = {
      kernelModules = [
        "fuse"
      ];
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "usbcore.autosuspend=-1"
    ];
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    loader = {
      systemd-boot = {
        configurationLimit = 10;
        enable = lib.mkForce false;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };
  # environment
  environment = {
    systemPackages = [
      pkgs.sbctl
    ];
  };
  # hardware
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        egl-wayland
        libGL
        libglvnd
        mesa
        nvidia-vaapi-driver
        libva-vdpau-driver
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libGL
        mesa
        libva-vdpau-driver
      ];
    };
    nvidia = {
      forceFullCompositionPipeline = true;
      modesetting = {
        enable = true;
      };
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement = {
        enable = true;
      };
    };
  };
  # power management
  powerManagement = {
    cpuFreqGovernor = "performance";
  };
  # services
  services = {
    fstrim = {
      enable = true;
      interval = "daily";
    };
    upower = {
      enable = true;
    };
  };
  # systemd
  systemd = {
    timers = {
      fstrim = {
        timerConfig = {
          Persistent = true;
        };
      };
    };
    user = {
      settings = {
        Manager = {
          DefaultTimeoutStopSec = "5s";
        };
      };
    };
  };
  # users
  users = {
    users = {
      "${username}" = {
        extraGroups = [
          "fuse"
          "networkmanager"
          "wheel"
          "audio"
          "video"
        ];
        home = "/${homePath}/${username}";
        isNormalUser = true;
        shell = pkgs.zsh;
      };
    };
  };
}
