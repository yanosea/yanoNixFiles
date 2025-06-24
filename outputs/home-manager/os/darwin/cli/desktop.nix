# home desktop module
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
      goku
      jankyborders
      nowplaying-cli
      sbar-lua
      sketchybar
      sketchybar-app-font
      switchaudio-osx
      skhd
      yabai
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
            PATH = "/usr/bin:/bin:/usr/sbin:/sbin:${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/sketchybar.error.log";
          StandardOutPath = "/tmp/sketchybar.log";
        };
      };
      skhd = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.skhd}/bin/skhd"
          ];
          EnvironmentVariables = {
            PATH = "${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/skhd.error.log";
          StandardOutPath = "/tmp/skhd.log";
        };
      };
      yabai = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.yabai}/bin/yabai"
          ];
          EnvironmentVariables = {
            PATH = "${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/yabai.error.log";
          StandardOutPath = "/tmp/yabai.log";
        };
      };
    };
  };
}
