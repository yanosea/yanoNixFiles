# darwin brew module
{
  # homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraEnv = {
        HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
      };
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
      "homerow"
      "karabiner-elements"
      "libreoffice"
      "libreoffice-language-pack"
      "mediosz/tap/swipeaerospace"
      "microsoft-auto-update"
      "nikitabobko/tap/aerospace"
      "obs"
      "omnidisksweeper"
      "processing"
      "qmk-toolbox"
      "raycast"
      "readdle-spark"
      "sf-symbols"
      "sonic-pi"
      "splashtop-personal"
      "splice"
      "spotify"
      "supercollider"
      "the-unarchiver"
      "touchdesigner"
      "vesktop"
      "via"
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
