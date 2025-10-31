# home game module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      steam
      (pkgs.vesktop.overrideAttrs (oldAttrs: {
        postFixup = (oldAttrs.postFixup or "") + ''
          wrapProgram $out/bin/vesktop \
            --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer" \
            --add-flags "--ozone-platform=wayland" \
            --add-flags "--disable-features=WebRtcHideLocalIpsWithMdns" \
            --add-flags "--enable-blink-features=PipeWireCamera"
        '';
      }))
    ];
  };
}
