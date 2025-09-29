# nixos system packages module
{ pkgs, ... }:
{
  # environment
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
      google-chrome
      killall
      libiconv
      lsof
      openssl
      openssl.dev
      patchelf
      pciutils
      pkg-config
      vim
    ];
  };
  # systemd
  systemd = {
    tmpfiles = {
      rules = [
        # create /opt/google/chrome symlink for Chrome MCP integration
        "d /opt 755 root root -"
        "d /opt/google 755 root root -"
        "d /opt/google/chrome 755 root root -"
        "L+ /opt/google/chrome/chrome - - - - ${pkgs.google-chrome}/bin/google-chrome-stable"
      ];
    };
  };
}
