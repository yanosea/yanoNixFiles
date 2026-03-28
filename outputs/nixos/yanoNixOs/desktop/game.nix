# nixos desktop game module
{ pkgs, ... }:
{
  # boot
  boot = {
    kernelModules = [
      "hid_sony"
    ];
  };
  # hardware
  hardware = {
    # steam hardware udev rules (controllers, vr headsets, etc.)
    steam-hardware = {
      enable = true;
    };
    # xbox wireless controller bluetooth driver
    xpadneo = {
      enable = true;
    };
  };
  # programs
  programs = {
    steam = {
      enable = true;
      dedicatedServer = {
        openFirewall = true;
      };
      localNetworkGameTransfers = {
        openFirewall = true;
      };
      remotePlay = {
        openFirewall = true;
      };
    };
  };
  # services
  services = {
    # nintendo switch joy-con / pro controller daemon
    joycond = {
      enable = true;
    };
  };
}
