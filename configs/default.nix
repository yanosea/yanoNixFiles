# configs (dotfiles)
{
  lib,
  ...
}:
let
  # local ai commands
  localAiCommands = builtins.readDir ./ai/commands;
  # create ai-related configuration entries
  aiConfigEntries =
    # add local ai commands to claude
    lib.mapAttrs' (name: _: {
      name = "claude/commands/${name}";
      value = {
        source = ./ai/commands + "/${name}";
      };
    }) localAiCommands;
  # regular config files (excluding default.nix, ai, and zsh directories)
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (
    name: _: name != "default.nix" && name != "ai" && name != "zsh"
  ) contents;
  mkEntry = name: type: {
    name = name;
    value = {
      source = ./. + "/${name}";
      recursive = type == "directory";
    };
  };
  configFiles = lib.mapAttrs' mkEntry filteredContents;
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
    "hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;
    "hypr/hyprpaper.conf".source = ./hypr/hyprpaper.conf;
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
  # xdg
  xdg = {
    configFile = configFiles // aiConfigEntries // hyprConfigEntries // zshConfigEntries;
  };
}
