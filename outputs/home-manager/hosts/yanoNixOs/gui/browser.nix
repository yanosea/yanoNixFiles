# home browser module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      floorp-bin-unwrapped
      vivaldi
    ];
  };
  # xdg
  xdg = {
    desktopEntries = {
      floorp = {
        name = "Floorp";
        genericName = "Web Browser";
        exec = "floorp --name floorp %U";
        icon = "floorp";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/vnd.mozilla.xul+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
        startupNotify = true;
        settings = {
          Version = "1.5";
          StartupWMClass = "floorp";
          Actions = "new-private-window;new-window;profile-manager-window";
        };
        actions = {
          new-private-window = {
            name = "New Private Window";
            exec = "floorp --private-window %U";
          };
          new-window = {
            name = "New Window";
            exec = "floorp --new-window %U";
          };
          profile-manager-window = {
            name = "Profile Manager";
            exec = "floorp --ProfileManager";
          };
        };
      };
    };
  };
}
