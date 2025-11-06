# darwin brew module
{
  # homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    brews = [
      "goku"
      "pinentry-mac"
    ];
    casks = [
      "ableton-live-suite"
      "appcleaner"
      "aquaskk"
      "arc"
      "bitwarden"
      "bitwig-studio"
      "blackhole-16ch"
      "blender"
      "chrome-remote-desktop-host"
      "contexts"
      "coteditor"
      "daisydisk"
      "easyfind"
      "font-sf-mono"
      "font-sf-pro"
      "github@beta"
      "google-chrome"
      "google-drive"
      "hammerspoon"
      "hiddenbar"
      "homerow"
      "karabiner-elements"
      "kiro"
      "libreoffice"
      "libreoffice-language-pack"
      "mediosz/tap/swipeaerospace"
      "microsoft-auto-update"
      "microsoft-teams"
      "nikitabobko/tap/aerospace"
      "obs"
      "omnidisksweeper"
      "processing"
      "qmk-toolbox"
      "raycast"
      "sf-symbols"
      "sonic-pi"
      "splashtop-personal"
      "splice"
      "spotify"
      "stats"
      "supercollider"
      "tailscale-app"
      "the-unarchiver"
      "touchdesigner"
      "vesktop"
      "via"
      "vibetunnel"
      "visual-studio-code"
      "vivaldi"
      "wezterm"
    ];
    taps = [
      "mediosz/tap"
      "nikitabobko/tap"
      "yqrashawn/goku"
    ];
  };
}
