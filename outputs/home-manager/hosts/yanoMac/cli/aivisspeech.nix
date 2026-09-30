# home aivisspeech module (the voice: speaks openclaw's tagged replies)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # loopback only: the engine has no auth and only openclaw on this host calls it
  host = "127.0.0.1";
  port = 10101;
  endpoint = "http://${host}:${toString port}";
  # style ids are derived from the model uuid, so the voice is picked by the
  # names `/speakers` reports rather than by a hardcoded id. this voice is not
  # a default model; on a fresh data dir install it once with
  #   curl -X POST -F url=https://hub.aivis-project.com/aivm-models/0f6821f4-9f86-4da1-a41a-fbe6fff9ca88 http://127.0.0.1:10101/aivm_models/install
  speaker = "天深シノ";
  defaultStyle = "ノーマル";
  # `pauseLength(Scale)` is not honoured by this engine (see its manifest), so
  # each sentence is synthesised on its own and joined with this much silence
  sentenceGap = "0.4";
  voiceParams = {
    intonationScale = "1.0";
    pitchScale = "0.0";
    speedScale = "0.92";
  };
  voiceFilter = lib.concatStringsSep " | " (
    lib.mapAttrsToList (key: value: ".${key} = ${value}") voiceParams
  );
  # openclaw's local cli provider hands over only the text, so the style
  # switches ride inside it as `【style】` markers (emoji would be stripped
  # before the command sees them). each marked run is synthesised with its
  # own style, sentence by sentence, and the pieces are joined into one wav.
  # the engine's g2p fails on some sokuon and dash combinations, so a failing
  # sentence is retried with those cleaned up, and dropped if it still fails
  aivis-say = pkgs.writeShellApplication {
    name = "aivis-say";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.sox
    ];
    text = ''
      text="''${1:-}"
      out="''${2:-}"
      if [ -z "$text" ] || [ -z "$out" ]; then
        echo "usage: aivis-say <text> <output.wav>" >&2
        exit 2
      fi
      styles=$(curl -fsS "${endpoint}/speakers" | jq -c --arg name "${speaker}" \
        '[.[] | select(.name == $name) | .styles[] | {(.name): .id}] | add // empty')
      if [ -z "$styles" ]; then
        echo "aivis-say: speaker ${speaker} is not installed in the engine" >&2
        exit 1
      fi
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT
      parts=()
      gap="$work/gap.wav"
      # matches the engine's output so sox can join without resampling
      sox -n -r 44100 -c 1 -b 16 "$gap" trim 0 ${sentenceGap}
      # synth <text> <style id>: appends one wav to parts, or returns 1
      synth() {
        local part="$work/''${#parts[@]}.wav" query
        query=$(curl -fsS -X POST --get \
          --data-urlencode "text=$1" \
          --data-urlencode "speaker=$2" \
          "${endpoint}/audio_query" 2>/dev/null) || return 1
        jq -c '${voiceFilter}' <<<"$query" |
          curl -fsS -X POST \
            -H 'Content-Type: application/json' \
            --data-binary @- \
            "${endpoint}/synthesis?speaker=$2" \
            -o "$part" || return 1
        if [ "''${#parts[@]}" -gt 0 ]; then
          parts+=("$gap")
        fi
        parts+=("$part")
      }
      while IFS= read -r segment; do
        style=$(jq -r '.style' <<<"$segment")
        run=$(jq -r '.text' <<<"$segment")
        id=$(jq -r --arg s "$style" '.[$s] // empty' <<<"$styles")
        if [ -z "$id" ]; then
          echo "aivis-say: unknown style $style, using ${defaultStyle}" >&2
          id=$(jq -r --arg s "${defaultStyle}" '.[$s]' <<<"$styles")
        fi
        while IFS= read -r sentence; do
          synth "$sentence" "$id" && continue
          cleaned=$(jq -rn --arg s "$sentence" \
            '$s | gsub("[—―]+"; "、") | gsub("(?<p>^|[、。…！？!?\\s])っ+"; "\(.p)")')
          synth "$cleaned" "$id" && continue
          echo "aivis-say: dropped a sentence the engine cannot read: $sentence" >&2
        done < <(jq -rn --arg t "$run" '$t | scan("[^。？！?!]+[。？！?!]*") | select(test("\\S"))')
      done < <(jq -nc --arg t "$text" --arg d "${defaultStyle}" '
        ($t | split("【")) as $runs
        | [{style: $d, text: $runs[0]}]
          + [$runs[1:][] | split("】")
             | if length == 1 then {style: $d, text: ("【" + .[0])}
               else {style: .[0], text: (.[1:] | join("】"))} end]
        | .[] | select(.text | test("\\S"))')
      if [ "''${#parts[@]}" -eq 0 ]; then
        echo "aivis-say: nothing to speak" >&2
        exit 1
      elif [ "''${#parts[@]}" -eq 1 ]; then
        mv "''${parts[0]}" "$out"
      else
        sox "''${parts[@]}" "$out"
      fi
    '';
  };
in
{
  # home
  home = {
    packages = [
      pkgs.aivisspeech-engine
      aivis-say
    ];
  };
  # programs
  programs = {
    openclaw = {
      # the voice lives here so the endpoint and the speaker stay next to the
      # engine that serves them
      config = {
        tts = {
          auto = "tagged";
          provider = "tts-local-cli";
          providers = {
            "tts-local-cli" = {
              command = "${aivis-say}/bin/aivis-say";
              args = [
                "{{Text}}"
                "{{OutputPath}}"
              ];
              # the engine answers 44.1kHz mono pcm; transcoding buys nothing
              outputFormat = "wav";
              # a model that is not resident yet loads on the first request
              timeoutMs = 120000;
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
      aivisspeech-engine = {
        enable = true;
        config = {
          # the first start pulls the default models and the bert weights
          # (about 900MB) into $XDG_DATA_HOME/AivisSpeech-Engine. the default
          # models cannot be uninstalled and come back on every start, so
          # nothing is preloaded: only the voice in use gets loaded, on its
          # first request
          ProgramArguments = [
            "${lib.getExe pkgs.aivisspeech-engine}"
            "--host"
            host
            "--port"
            (toString port)
            "--disable_sentry"
          ];
          EnvironmentVariables = {
            PATH = "${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/aivisspeech-engine.error.log";
          StandardOutPath = "/tmp/aivisspeech-engine.log";
        };
      };
    };
  };
}
