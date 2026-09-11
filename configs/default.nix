# configs (dotfiles)
{
  lib,
  ...
}:
let
  # regular config files (excluding default.nix, agents, antigravity, codex, and zsh directories)
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (
    name: _:
    name != "default.nix"
    && name != "agents"
    && name != "antigravity"
    && name != "codex"
    && name != "zsh"
  ) contents;
  mkEntry = name: type: {
    inherit name;
    value = {
      source = ./. + "/${name}";
      recursive = type == "directory";
    };
  };
  configFiles = lib.mapAttrs' mkEntry filteredContents;
  quickshellOverride = {
    "quickshell" = configFiles."quickshell" // {
      force = true;
    };
  };
  # hypr config files with custom onChange hook for hyprland.conf
  hyprConfigEntries = {
    "hypr/hyprland.conf" = {
      source = ./hypr/hyprland.conf;
      onChange = ''
        XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
        if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
          # Check if hyprctl actually returns valid JSON before piping to jq
          INSTANCES=$(hyprctl instances -j 2>/dev/null || echo "[]")
          # Only proceed if we have valid JSON array
          if echo "$INSTANCES" | jq empty 2>/dev/null; then
            for i in $(echo "$INSTANCES" | jq ".[].instance" -r 2>/dev/null); do
              hyprctl -i "$i" reload config-only 2>/dev/null || true
            done
          fi
        fi
      '';
    };
    "hypr/hypridle.conf".source = ./hypr/hypridle.conf;
    "hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;
  };
  # codex config files (config.toml is deployed by an activation copy instead,
  # since codex writes hook-trust and project-trust state back into it)
  codexConfigEntries = {
    "codex/plugins.conf".source = ./codex/plugins.conf;
    "codex/hooks" = {
      source = ./codex/hooks;
      recursive = true;
    };
    "codex/themes" = {
      source = ./codex/themes;
      recursive = true;
    };
  };
  # zsh config subdirectories (excluding .zshrc/.zshenv which are managed by programs.zsh)
  zshContents = builtins.readDir ./zsh;
  zshConfigEntries = lib.mapAttrs' (name: type: {
    name = "zsh/${name}";
    value = {
      source = ./zsh + "/${name}";
      recursive = type == "directory";
    };
  }) zshContents;
in
{
  # home directory files
  home = {
    activation = {
      # copied rather than symlinked: codex appends [hooks.state] and
      # [projects.*] to config.toml and cannot write to a store path.
      # config.local.toml goes first so its top-level keys precede every table,
      # which keeps unpublishable settings out of this repository
      copyCodexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        codexDir="''${XDG_CONFIG_HOME:-$HOME/.config}/codex"
        $DRY_RUN_CMD mkdir -p "$codexDir"
        if [ -f "$codexDir/config.local.toml" ]; then
          $DRY_RUN_CMD cat "$codexDir/config.local.toml" ${./codex/config.toml} >"$codexDir/config.toml"
        else
          $DRY_RUN_CMD cat ${./codex/config.toml} >"$codexDir/config.toml"
        fi
        $DRY_RUN_CMD chmod 644 "$codexDir/config.toml"
      '';
    };
    file = {
      # codex skills live outside XDG, in the cross-tool ~/.agents/skills
      ".agents" = {
        source = ./agents;
        recursive = true;
      };
      ".gemini/antigravity-cli" = {
        source = ./antigravity;
        recursive = true;
        force = true;
      };
      ".local/bin/niri-app-toggle" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          APP_ID="$1"
          shift
          WINDOWS=$(niri msg -j windows 2>/dev/null)
          UNFOCUSED_ID=$(printf '%s' "$WINDOWS" | jq -r --arg a "$APP_ID" \
            'first(.[] | select(.app_id == $a and .is_focused == false) | .id) // empty')
          if [ -n "$UNFOCUSED_ID" ]; then
            niri msg action focus-window --id "$UNFOCUSED_ID"
          elif ! printf '%s' "$WINDOWS" | jq -e --arg a "$APP_ID" 'any(.[]; .app_id == $a)' >/dev/null 2>&1; then
            exec "$@"
          fi
        '';
      };
    };
  };
  # xdg
  xdg = {
    configFile =
      configFiles // quickshellOverride // codexConfigEntries // hyprConfigEntries // zshConfigEntries;
  };
}
