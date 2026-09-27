# home whisper module (the ear: transcribes inbound voice for openclaw)
{
  pkgs,
  ...
}:
let
  # nixpkgs carries whisper.cpp but no ggml weights, so the model is pinned
  # here. `large-v3-turbo` is the balance point: multilingual accuracy close to
  # `large-v3` at a fraction of the runtime on Metal
  model = pkgs.fetchurl {
    name = "ggml-large-v3-turbo.bin";
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin";
    hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
  };
in
{
  # home
  home = {
    packages = [
      pkgs.whisper-cpp
    ];
  };
  # programs
  programs = {
    openclaw = {
      config = {
        tools = {
          media = {
            audio = {
              enabled = true;
              language = "ja";
            };
            # this arg list mirrors the one openclaw builds for its own
            # whisper-cli backend, and the shape matters:
            #   - `{{OutputBase}}` already expands to an absolute path inside a
            #     freshly made temp dir, so prefixing `{{OutputDir}}/` produces
            #     a doubled path, whisper writes nothing, and the attachment
            #     comes back as "could not be analyzed"
            #   - `-otxt` is what produces the `<base>.txt` openclaw reads back
            #   - the input is positional; `-nt` drops the timestamps so the
            #     file holds the plain sentence
            # no input preparation is needed: openclaw runs ffmpeg first and
            # hands over 16kHz mono wav
            models = [
              {
                capabilities = [ "audio" ];
                command = "${pkgs.whisper-cpp}/bin/whisper-cli";
                args = [
                  "-m"
                  "${model}"
                  "-l"
                  "ja"
                  "-otxt"
                  "-of"
                  "{{OutputBase}}"
                  "-nt"
                  "{{AttachmentPath}}"
                ];
              }
            ];
          };
        };
      };
    };
  };
}
