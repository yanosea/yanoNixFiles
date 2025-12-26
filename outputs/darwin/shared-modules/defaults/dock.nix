# dock configuration
{ ... }:
{
  # system
  system = {
    defaults = {
      dock = {
        enable-spring-load-actions-on-all-items = true;
        appswitcher-all-displays = false;
        autohide = true;
        autohide-delay = 0.25;
        autohide-time-modifier = 0.25;
        dashboard-in-overlay = true;
        expose-animation-duration = 1.0;
        expose-group-apps = true;
        largesize = 120;
        launchanim = true;
        magnification = true;
        mineffect = "genie";
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        mru-spaces = false;
        orientation = "bottom";
        persistent-apps = [
          {
            app = "/Applications/Vivaldi.app";
          }
          {
            app = "/Applications/Spark Desktop.app";
          }
          {
            app = "/Applications/Vesktop.app";
          }
          {
            app = "/Applications/WezTerm.app";
          }
          {
            app = "/Applications/Ableton Live 12 Suite.app";
          }
          {
            app = "/Applications/Bitwig Studio.app";
          }
          {
            app = "/Applications/Native Instruments/Traktor DJ 2/Traktor DJ.app";
          }
          {
            app = "/Applications/Splice.app";
          }
          {
            app = "/Applications/SuperCollider.app";
          }
          {
            app = "/Applications/TouchDesigner.app";
          }
          {
            app = "/Applications/Processing.app";
          }
          {
            app = "/Applications/Sonic Pi.app";
          }
          {
            app = "/System/Applications/Utilities/Screen Sharing.app";
          }
          {
            app = "/System/Applications/System Settings.app";
          }
        ];
        persistent-others = null;
        scroll-to-open = true;
        show-process-indicators = true;
        show-recents = false;
        showhidden = true;
        slow-motion-allowed = true;
        static-only = false;
        tilesize = 128;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };
    };
  };
}
