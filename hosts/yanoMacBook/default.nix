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
    ## brew
    ../../modules/programs/brew.nix
    ## shell
    ../../modules/programs/shell.nix
  ];
  # fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts-emoji
      plemoljp-nf
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
