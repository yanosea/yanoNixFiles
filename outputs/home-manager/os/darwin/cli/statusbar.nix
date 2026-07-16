# darwin status bar module (borders + sketchybar)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  sbar-lua = pkgs.stdenv.mkDerivation rec {
    pname = "SbarLua";
    version = "2024-08-13";
    src = pkgs.fetchFromGitHub {
      owner = "FelixKratz";
      repo = pname;
      rev = "437bd2031da38ccda75827cb7548e7baa4aa9978";
      sha256 = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
    };
    buildInputs = with pkgs; [
      gcc
      lua5_4
      readline
    ];
    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/sketchybar.so $out/bin/
    '';
    meta = with lib; {
      description = "SketchyBar Lua Plugin";
      homepage = "https://github.com/FelixKratz/SbarLua";
      platforms = platforms.darwin;
    };
  };
in
{
  # home
  home = {
    packages = with pkgs; [
      jankyborders
      nowplaying-cli
      sbar-lua
      sketchybar
      switchaudio-osx
    ];
  };
  # launchd
  launchd = {
    enable = true;
    agents = {
      borders = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.jankyborders}/bin/borders"
          ];
          EnvironmentVariables = {
            PATH = "${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/borders.error.log";
          StandardOutPath = "/tmp/borders.log";
        };
      };
      sketchybar = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.sketchybar}/bin/sketchybar"
          ];
          EnvironmentVariables = {
            # /opt/homebrew/bin is needed for `aerospace`, which items/spaces.lua shells out to
            PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/sketchybar.error.log";
          StandardOutPath = "/tmp/sketchybar.log";
        };
      };
    };
  };
}
