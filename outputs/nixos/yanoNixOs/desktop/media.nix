# nixos desktop media module
{ config, ... }:
{
  # boot
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  };

  # programs
  programs = {
    obs-studio = {
      enable = true;
    };
  };
}
