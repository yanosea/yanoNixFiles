{ pkgs, ... }: {
  # environment
  environment = {
    systemPackages = with pkgs; [
      acpi
      bottom
      btrfs-progs
      cargo-make
      clang
      duf
      gcc
      ghq
      git
      gnumake
      lf
      libiconv
      lsof
      openssl
      openssl.dev
      patchelf
      pciutils
      pkg-config
      rclone
      vim
      zsh
    ];
  };
  # nix
  nix = { envVars = { ZDOTDIR = "$HOME/.config/zsh"; }; };
}
