# nixos desktop graphics tools module
{ pkgs, ... }:
{
  # environment
  environment = {
    systemPackages = with pkgs; [
      libva-utils
      mesa-demos
      vdpauinfo
      vulkan-tools
    ];
  };
}
