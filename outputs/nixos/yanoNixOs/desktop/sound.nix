# nixos desktop sound module
{ pkgs, ... }:
{
  # environment
  environment = {
    systemPackages = with pkgs; [
      pulseaudio
      pavucontrol
    ];
  };
  # programs
  programs = {
    noisetorch = {
      enable = true;
    };
  };
  # security
  security = {
    rtkit = {
      enable = true;
    };
  };
  # services
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack = {
        enable = true;
      };
      pulse = {
        enable = true;
      };
      wireplumber = {
        enable = true;
      };
    };
    pulseaudio = {
      enable = false;
    };
  };
}
