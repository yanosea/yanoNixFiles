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
    ## nix-ld
    ../../modules/programs/nix-ld.nix
    ## shell
    ../../modules/programs/shell.nix
  ];
  # boot
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        device = "nodev";
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
