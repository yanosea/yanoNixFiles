{ inputs, pkgs, username, ... }: {
  imports = [
    # modules
    ../../modules/core
    ../../modules/programs/flatpak.nix
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/shell.nix
  ];
  # system
  system = {
    stateVersion = "24.05";
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
}
