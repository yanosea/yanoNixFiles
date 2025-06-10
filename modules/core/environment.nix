{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      acpi
      bottom
      btrfs-progs
      clang
      duf
      gcc
      ghq
      git
      gnumake
      killall
      libiconv
      lsof
      openssl
      openssl.dev
      patchelf
      pciutils
      pkg-config
      rclone
      vim
    ];
  };
}
