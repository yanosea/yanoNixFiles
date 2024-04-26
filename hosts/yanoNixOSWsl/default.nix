{ pkgs, ... }: {
  imports = [
    ../../modules/nixos_wsl
  ];
  users.users.yanosea = {
    isNormalUser = true;
    description = "yanosea";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  networking.hostName = "yanoNixOSWsl";
  # programs
  programs = {
    zsh = {
      enable = true;
    };
  };
}
