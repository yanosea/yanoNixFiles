# home secrets module
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  ageKeyFile = "${config.xdg.configHome}/sops/age/keys.txt";
in
{
  # home
  home = {
    # automatic age key generation
    activation = {
      generateAgeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ ! -f "${ageKeyFile}" ]]; then
          echo "Generating age key..."
          mkdir -p "$(dirname "${ageKeyFile}")"
          ${pkgs.age}/bin/age-keygen -o "${ageKeyFile}"
          chmod 600 "${ageKeyFile}"
          echo "Generated age key at ${ageKeyFile}"
          echo ""
          echo -e "\033[1;33mPublic key:\033[0m"
          ${pkgs.age}/bin/age-keygen -y "${ageKeyFile}"
          echo ""
        fi
      '';
    };
    packages = with pkgs; [
      age
      sops
    ];
  };
  # sops
  sops = {
    age = {
      keyFile = ageKeyFile;
    };
    defaultSopsFile = inputs.self + "/ops/sops/credentials.enc.yaml";
    secrets = {
      ANTHROPIC_API_KEY = {
        path = "${config.xdg.dataHome}/sops/ANTHROPIC_API_KEY";
      };
      OPENAI_API_KEY = {
        path = "${config.xdg.dataHome}/sops/OPENAI_API_KEY";
      };
      RCLONE_CONFIG = {
        path = "${config.xdg.configHome}/rclone/rclone.conf";
      };
      SPOTIFY_ID = {
        path = "${config.xdg.dataHome}/sops/SPOTIFY_ID";
      };
      SPOTIFY_REDIRECT_URI = {
        path = "${config.xdg.dataHome}/sops/SPOTIFY_REDIRECT_URI";
      };
      SPOTIFY_REFRESH_TOKEN = {
        path = "${config.xdg.dataHome}/sops/SPOTIFY_REFRESH_TOKEN";
      };
      SPOTIFY_SECRET = {
        path = "${config.xdg.dataHome}/sops/SPOTIFY_SECRET";
      };
      TAVILY_API_KEY = {
        path = "${config.xdg.dataHome}/sops/TAVILY_API_KEY";
      };
      TRELLO_KEY = {
        path = "${config.xdg.dataHome}/sops/TRELLO_KEY";
      };
      TRELLO_TOKEN = {
        path = "${config.xdg.dataHome}/sops/TRELLO_TOKEN";
      };
      TRELLO_USER = {
        path = "${config.xdg.dataHome}/sops/TRELLO_USER";
      };
    };
  };
}
