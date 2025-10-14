# configs (dotfiles)
{
  lib,
  ...
}:
let
  # regular config files (excluding default.nix and ai directory)
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (name: _: name != "default.nix" && name != "ai") contents;
  mkEntry = name: type: {
    name = name;
    value = {
      source = ./. + "/${name}";
      recursive = type == "directory";
    };
  };
  configFiles = lib.mapAttrs' mkEntry filteredContents;
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
in
{
  # xdg
  xdg = {
    configFile = configFiles // aiConfigEntries;
  };
}
