{
  config,
  homePath,
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # hardware-configuration
    ./hardware-configuration.nix
    # core
    ../../modules/core
    # desktop
    ../../modules/desktop
    # nix
    ../../modules/nix/nix.nix
    # programs
    ../../modules/programs/hyprland.nix
    ../../modules/programs/media.nix
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/shell.nix
    ../../modules/programs/steam.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [ common-pc-ssd ]);
  # boot
  boot = {
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
    };
    initrd = {
      kernelModules = [ "nvidia" ];
    };
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };
  # hardware
  hardware = {
    bluetooth = {
      enable = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
      extraPackages32 = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    nvidia = {
      forceFullCompositionPipeline = true;
      modesetting = {
        enable = true;
      };
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      powerManagement = {
        enable = true;
      };
    };
  };
  # services
  services = {
    # blueman
    blueman = {
      enable = true;
    };
    # greetd
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
          ExecStart = "${pkgs.rclone}/bin/rclone mount yanosea: /mnt/google_drive/yanosea --allow-other --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M --drive-chunk-size 64M --config /.rclone.conf";
        };
      };
    };
  };
  # time
  time = {
    hardwareClockInLocalTime = true;
  };
  # users
  users = {
    users = {
      "${username}" = {
        extraGroups = [
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
