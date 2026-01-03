# configs (dotfiles)
{
  lib,
  ...
}:
let
  # regular config files (excluding default.nix, zsh, and gemini directories)
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (
    name: _: name != "default.nix" && name != "gemini" && name != "zsh"
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
  # home directory files
  home.file = {
    ".gemini" = {
      source = ./gemini;
      recursive = true;
    };
  };
  # xdg
  xdg = {
    configFile = configFiles // hyprConfigEntries // zshConfigEntries;
  };
}
