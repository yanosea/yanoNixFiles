# home tools module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      baobab
      blender
      kdePackages.kdenlive
      libreoffice-fresh
      remmina
      (vesktop.overrideAttrs (oldAttrs: {
        postFixup = (oldAttrs.postFixup or "") + ''
          wrapProgram $out/bin/vesktop \
            --add-flags "--disable-features=WebRtcHideLocalIpsWithMdns" \
            --add-flags "--enable-blink-features=PipeWireCamera" \
            --add-flags "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer" \
            --add-flags "--ozone-platform=wayland"
        '';
      }))
    ];
  };
}
