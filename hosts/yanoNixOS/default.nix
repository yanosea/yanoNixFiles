{ inputs, pkgs, username, ... }: {
  imports = [
    # hardware-configuration
    ./hardware-configuration.nix
    # modules
    ../../modules/core
    ../../modules/desktop
    ../../modules/programs/flatpak.nix
    ../../modules/programs/hyprland.nix
    ../../modules/programs/media.nix
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/secureboot.nix
    ../../modules/programs/shell.nix
    ../../modules/programs/steam.nix
    ../../modules/programs/xserver.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-gpu-amd
    common-pc-ssd
  ]);
  # system
  system = {
    stateVersion = "24.05";
  };
  # boot
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      kernelModules = [
        "nvidia"
      ];
    };
    extraModulePackages = [
      config.boot.kernelPackages.nvidia_x11
    ];
    binfmt = {
      emulatedSystems = [
        "aarch64-linux"
      ];
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };
  # users
  users.users."${username}" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
    ];
  };
  # hardware
  hardware = {
    bluetooth = {
      enable = true;
    };
  };
  # time
  time = {
    hardwareClockInLocalTime = true;
  };
  # services
  services = {
    # blueman
    blueman = {
      enable = true;
    };
    # greedt
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland
          '';
          user = username;
        };
      };
    };
    # upower
    upower = {
      enable = true;
    };
  };
  # systemd
  systemd = {
    services = {
      # rclone
      rclone = {
        enable = true;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "default.target" ];
        description = "rclone service";
        serviceConfig = {
          ExecStart = "${pkgs.rclone}/bin/rclone mount yanosea: /mnt/google_drive/yanosea --allow-other --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M --drive-chunk-size 64M";
        };
      };
    };
  };
}
