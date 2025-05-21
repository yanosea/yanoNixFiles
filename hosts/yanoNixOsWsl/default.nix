{
  homePath,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # core
    ../../modules/core
  ];
  # boot
  boot = {
    loader = {
      grub = {
        device = "nodev";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
  # programs
  programs = {
    zsh = {
      enable = true;
    };
  };
  # system
  system = {
    stateVersion = "24.11";
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
