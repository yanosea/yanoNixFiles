# home daw module
{ pkgs, ... }:
let
  bitwigWrapper = pkgs.writeShellScriptBin "bitwig-studio-wrapped" ''
    export DISABLE_VK_LAYER_LUNARG_api_dump=1
    export DISABLE_VK_LAYER_LUNARG_core_validation=1
    export VK_INSTANCE_LAYERS=""
    export VK_DRIVER_FILES=""
    exec ${pkgs.bitwig-studio}/bin/bitwig-studio "$@"
  '';
in
{
  # home
  home = {
    packages = with pkgs; [
      bitwig-studio
      bitwigWrapper
    ];
    sessionVariables = {
      DISABLE_VK_LAYER_LUNARG_api_dump = "1";
      DISABLE_VK_LAYER_LUNARG_core_validation = "1";
      VK_INSTANCE_LAYERS = "";
      VK_DRIVER_FILES = "";
    };
  };
  # xdg
  xdg = {
    desktopEntries = {
      "com.bitwig.BitwigStudio" = {
        name = "Bitwig Studio";
        noDisplay = true;
      };
      bitwig-studio = {
        name = "Bitwig Studio";
        genericName = "Digital Audio Workstation";
        comment = "Modern music production and performance";
        exec = "${bitwigWrapper}/bin/bitwig-studio-wrapped";
        icon = "com.bitwig.BitwigStudio";
        terminal = false;
        categories = [
          "AudioVideo"
          "Music"
          "Audio"
          "Sequencer"
          "Midi"
          "Mixer"
          "Player"
          "Recorder"
        ];
        mimeType = [
          "application/bitwig-clip"
          "application/bitwig-device"
          "application/bitwig-package"
          "application/bitwig-preset"
          "application/bitwig-project"
          "application/bitwig-scene"
          "application/bitwig-template"
          "application/bitwig-extension"
          "application/bitwig-remote-controls"
          "application/bitwig-module"
          "application/bitwig-modulator"
          "application/vnd.bitwig.dawproject"
        ];
        startupNotify = true;
      };
    };
  };
}
