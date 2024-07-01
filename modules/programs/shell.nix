{ pkgs, ... }: {
  # programs
  programs = {
    git = {
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
      cargo
      cargo-make
      duf
      gcc
      ghq
      git
      gum
      lsof
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
