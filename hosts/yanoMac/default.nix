{ pkgs, username, ... }: {
  imports = [
    # modules
    ../../modules/core
    ../../modules/programs/flatpak.nix
    ../../modules/programs/nix-ld.nix
    ../../modules/programs/shell.nix
  ];
  # users
  users.users."${username}" = {
    shell = pkgs.zsh;
    home = "/Users/${username}";
  };
}
