# configs (dotfiles)
{ lib, ... }:
let
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (
    name: _: name != "default.nix" && name != "ai-commands"
  ) contents;
  mkEntry = name: type: {
    name = name;
    value = {
      source = ./. + "/${name}";
      recursive = type == "directory";
    };
  };
  configFiles = lib.mapAttrs' mkEntry filteredContents;
  # ai commands shared across different tools
  aiCommands = builtins.readDir ./ai-commands;
  aiCommandEntries =
    lib.mapAttrs' (name: _: {
      name = "claude/commands/${name}";
      value = {
        source = ./ai-commands + "/${name}";
      };
    }) aiCommands
    // lib.mapAttrs' (name: _: {
      name = "opencode/instructions/${name}";
      value = {
        source = ./ai-commands + "/${name}";
      };
    }) aiCommands;
in
{
  # xdg
  xdg = {
    configFile = configFiles // aiCommandEntries;
  };
}
