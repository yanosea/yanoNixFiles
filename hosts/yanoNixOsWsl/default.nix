{ homePath, inputs, pkgs, username, ... }: {
  imports = [
    # core
    ../../modules/core/i18n.nix
    ../../modules/core/network.nix
    ../../modules/core/nix.nix
    ../../modules/core/security.nix
    ../../modules/core/virtualisation.nix
    # programs
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/shell.nix
  ];
  # boot
  boot = {
    loader = { grub = { device = "nodev"; }; };
    kernelPackages = pkgs.linuxPackages_latest;
  };
  # programs
  programs = { zsh = { enable = true; }; };
  # system
  system = { stateVersion = "24.11"; };
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
  # wsl
  wsl = {
    enable = true;
    defaultUser = "yanosea";
    wslConf = {
      automount = { root = "/mnt"; };
      interop = {
        appendWindowsPath = false;
        enabled = true;
      };
      network = { generateHosts = false; };
    };
  };
}
