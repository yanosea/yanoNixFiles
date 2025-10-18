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
    activation = {
      # automatic age key generation
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
      # automatic gpg key import
      importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ -f "${config.xdg.dataHome}/sops/GPG_PRIVATE_KEY" ]]; then
          echo "Importing GPG key..."
          ${pkgs.gnupg}/bin/gpg --import "${config.xdg.dataHome}/sops/GPG_PRIVATE_KEY" 2>/dev/null || true
          # Set trust level to ultimate
          GPG_KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons 81510859+yanosea@users.noreply.github.com 2>/dev/null | grep '^fpr' | head -1 | cut -d: -f10)
          if [[ -n "$GPG_KEY_ID" ]]; then
            echo "Setting GPG key trust level to ultimate..."
            echo "$GPG_KEY_ID:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust 2>/dev/null || true
            echo "GPG key trust level set successfully"
          fi
          echo "GPG key imported successfully"
        fi
      '';
    };
    packages = with pkgs; [
      age
      gnupg
      pinentry-curses
      sops
    ];
  };
  # services
  services = {
    gpg-agent = {
      enable = true;
      pinentry = {
        package = pkgs.pinentry-curses;
      };
      enableSshSupport = false;
    };
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
      GPG_PRIVATE_KEY = {
        path = "${config.xdg.dataHome}/sops/GPG_PRIVATE_KEY";
      };
    };
  };
}
