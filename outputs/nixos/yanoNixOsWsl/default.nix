# nixos (wsl) configuration
{
  homePath,
  lib,
  pkgs,
  username,
  ...
}:
{
  # boot
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        device = "nodev";
      };
    };
  };
  # networking
  networking = {
    wireless = {
      enable = lib.mkForce false;
    };
  };
  # systemd
  systemd = {
    services = {
      wpa_supplicant = {
        enable = lib.mkForce false;
      };
    };
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
        home = "${homePath}/${username}";
        isNormalUser = true;
        shell = pkgs.zsh;
      };
    };
  };
  # wsl
  wsl = {
    enable = true;
    defaultUser = username;
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
