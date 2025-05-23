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
    # nix
    ../../modules/nix/nix.nix
    # programs
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/shell.nix
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
