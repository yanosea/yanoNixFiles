{ config, homePath, inputs, pkgs, username, ... }: {
  imports = [
    # hardware-configuration
    ./hardware-configuration.nix
    # core
    ../../modules/core/i18n.nix
    ../../modules/core/network.nix
    ../../modules/core/nix.nix
    ../../modules/core/security.nix
    ../../modules/core/virtualisation.nix
    # desktop
    ../../modules/desktop
    # programs
    ../../modules/programs/flatpak.nix
    ../../modules/programs/hyprland.nix
    ../../modules/programs/media.nix
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/shell.nix
    ../../modules/programs/steam.nix
    ../../modules/programs/xserver.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [ common-pc-ssd ]);
  # boot
  boot = {
    binfmt = { emulatedSystems = [ "aarch64-linux" ]; };
    initrd = { kernelModules = [ "nvidia" ]; };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = { canTouchEfiVariables = true; };
    };
  };
  # hardware
  hardware = {
    bluetooth = { enable = true; };
    graphics = { enable = true; };
    nvidia = {
      forceFullCompositionPipeline = true;
      modesetting = { enable = true; };
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      powerManagement = { enable = true; };
    };
  };
  # programs
  programs = { zsh = { enable = true; }; };
  # services
  services = {
    # blueman
    blueman = { enable = true; };
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
    upower = { enable = true; };
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
          ExecStart =
            "${pkgs.rclone}/bin/rclone mount yanosea: /mnt/google_drive/yanosea --allow-other --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M --drive-chunk-size 64M --config /.rclone.conf";
        };
      };
    };
  };
  # system
  system = { stateVersion = "24.11"; };
  # time
  time = { hardwareClockInLocalTime = true; };
  # users
  users = {
    users = {
      "${username}" = {
        extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
        home = "/${homePath}/${username}";
        isNormalUser = true;
        shell = pkgs.zsh;
      };
    };
  };
}
