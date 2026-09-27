# home voicevox module
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # loopback only: the engine has no auth and only openclaw on this host calls it
  host = "127.0.0.1";
  port = 50021;
  endpoint = "http://${host}:${toString port}";
  speaker = 14;
  voiceParams = {
    intonationScale = "1.5";
    speedScale = "0.92";
    pauseLengthScale = "1.3";
    pitchScale = "0.04";
  };
  voiceFilter = lib.concatStringsSep " | " (
    lib.mapAttrsToList (key: value: ".${key} = ${value}") voiceParams
  );
  voicevox-say = pkgs.writeShellApplication {
    name = "voicevox-say";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      text="''${1:-}"
      out="''${2:-}"
      if [ -z "$text" ] || [ -z "$out" ]; then
        echo "usage: voicevox-say <text> <output.wav>" >&2
        exit 2
      fi
      query=$(curl -fsS -X POST --get \
        --data-urlencode "text=$text" \
        --data-urlencode "speaker=${toString speaker}" \
        "${endpoint}/audio_query")
      printf '%s' "$query" | jq -c '${voiceFilter}' | curl -fsS -X POST \
        -H 'Content-Type: application/json' \
        --data-binary @- \
        "${endpoint}/synthesis?speaker=${toString speaker}" \
        -o "$out"
    '';
  };
in
{
  # home
  home = {
    packages = [
      pkgs.voicevox-engine
      voicevox-say
    ];
  };
  # programs
  programs = {
    openclaw = {
      # the voice lives here so the endpoint and the speaker id stay next to
      # the engine that serves them
      config = {
        tts = {
          auto = "tagged";
          provider = "tts-local-cli";
          providers = {
            "tts-local-cli" = {
              command = "${voicevox-say}/bin/voicevox-say";
              args = [
                "{{Text}}"
                "{{OutputPath}}"
              ];
              # the engine answers 24kHz mono pcm; transcoding buys nothing
              outputFormat = "wav";
            };
          };
        };
      };
    };
  };
  # launchd
  launchd = {
    enable = true;
    agents = {
      voicevox-engine = {
        enable = true;
        config = {
          ProgramArguments = [
            "${lib.getExe pkgs.voicevox-engine}"
            "--host"
            host
            "--port"
            (toString port)
          ];
          EnvironmentVariables = {
            PATH = "${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/voicevox-engine.error.log";
          StandardOutPath = "/tmp/voicevox-engine.log";
        };
      };
    };
  };
}
