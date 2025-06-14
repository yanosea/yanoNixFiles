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
    };
  };
}
