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
      "google-drive"
      "hammerspoon"
      "hiddenbar"
      "karabiner-elements"
      "launchpad-manager"
      "libreoffice"
      "libreoffice-language-pack"
      "microsoft-auto-update"
      "microsoft-teams"
      "obs"
      "omnidisksweeper"
      "onyx"
      "processing"
      "qmk-toolbox"
      "raycast"
      "sf-symbols"
      "sonic-pi"
      "splashtop-personal"
      "splice"
      "spotify"
      "supercollider"
      "the-unarchiver"
      "touchdesigner"
      "via"
      "visual-studio-code"
      "vivaldi"
      "wezterm"
    ];
  };
}
