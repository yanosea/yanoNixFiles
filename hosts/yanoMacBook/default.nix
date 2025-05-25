{
  hostname,
  homePath,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # nix
    ../../modules/nix/nix-darwin.nix
    # programs
    ../../modules/programs/shell.nix
  ];
  # fonts
  fonts = {
    packages = with pkgs; [
      plemoljp-nf
      noto-fonts-emoji
    ];
  };
  # networking
  networking = {
    hostName = hostname;
  };
  # system
  system = {
    stateVersion = 6;
  };
  # users
  users = {
    users = {
      "${username}" = {
        home = "/${homePath}/${username}";
        shell = pkgs.zsh;
      };
    };
  };
}
