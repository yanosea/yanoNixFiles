{ pkgs, ... }: {
  imports = [
    ../../modules/nixos
    ./hardware-configuration.nix
  ];
  users.users.yanosea = {
    isNormalUser = true;
    description = "yanosea";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  networking.hostName = "yanoNixOS";
  # programs
  programs = {
    zsh = {
      enable = true;
    };
  };
}
