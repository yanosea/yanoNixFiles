# darwin brew module
{
  # homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
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
      "font-sketchybar-app-font"
      "github@beta"
      "google-drive"
      "hammerspoon"
      "hiddenbar"
      "homerow"
      "karabiner-elements"
      "kiro"
      "libreoffice"
      "libreoffice-language-pack"
      "microsoft-auto-update"
      "microsoft-teams"
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
      "supercollider"
      "tailscale"
      "the-unarchiver"
      "touchdesigner"
      "via"
      "vibetunnel"
      "visual-studio-code"
      "vivaldi"
      "wezterm"
    ];
  };
}
