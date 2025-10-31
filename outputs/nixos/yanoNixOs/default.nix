# nixos configuration
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
