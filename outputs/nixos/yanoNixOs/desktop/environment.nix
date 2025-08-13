# nixos desktop environment module
{
  # environment
  environment = {
    variables = {
      CHROMIUM_FLAGS = "--enable-features=VaapiVideoDecoder --disable-features=UseChromeOSDirectVideoDecoder";
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
      VDPAU_DRIVER = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __NV_PRIME_RENDER_OFFLOAD = "1";
    };
  };
}
