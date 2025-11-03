# nixos desktop media module
{ config, pkgs, ... }:
{
  # boot
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  };
  # programs
  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
        obs-vaapi
        obs-vkcapture
      ];
    };
  };
}
