{
  pkgs,
  ...
}: {
  # programs
  programs = {
    git = {
      enable = true;
    };
    git-credential-oauth = {
      enable = true;
    };
    lunarvim = {
      enable = true;
      defaultEditor = true;
    };
    neovim = {
      enable = true;
    };
    vim = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
  };
  # environment
  environment = {
    systemPackages = with pkgs; [
      acpi
      bottom
      btrfs-progs
      cargo-make
      duf
      gcc
      git
      git-credential-oauth
      lunarvim
      lsof
      neovim
      openssl
      openssl.dev
      pciutils
      pkg-config
      vim
      zsh
    ];
  };
  # nix
  nix = {
    envVars = {
      ZDOTDIR = "$HOME/.config/zsh";
    };
  };
}
