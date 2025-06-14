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
    ## game
    ../../modules/programs/game.nix
    ## google-drive
    ../../modules/programs/google-drive.nix
    ## nix-ld
    ../../modules/programs/nix-ld.nix
    ## shell
    ../../modules/programs/shell.nix
  ] ++ (with inputs.nixos-hardware.nixosModules; [ common-pc-ssd ]);
  # boot
  boot = {
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
    };
    initrd = {
      kernelModules = [
        "fuse"
        "nvidia"
      ];
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
    upower = {
      enable = true;
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
