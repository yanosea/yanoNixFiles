{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      pulseaudio
      pavucontrol
    ];
    variables = {
      LIBVA_DRIVER_NAME = "nvidia";
      VDPAU_DRIVER = "nvidia";
      CHROMIUM_FLAGS = "--enable-features=VaapiVideoDecoder --disable-features=UseChromeOSDirectVideoDecoder";
    };
  };
}
