# configs (dotfiles)
{
  lib,
  inputs,
  ...
}:
let
  # use external repository from flake inputs
  claudeCodeSpecSrc = inputs.claude-code-spec;
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
  # get kiro commands from fetched source
  kiroCommands = builtins.readDir "${claudeCodeSpecSrc}/.claude/commands/kiro";
  # create ai-related configuration entries
  aiConfigEntries = {
    # claude configuration - use external CLAUDE.md
    "claude/CLAUDE.md" = {
      source = "${claudeCodeSpecSrc}/CLAUDE.md";
    };
    # gemini configuration
    "gemini/GEMINI.md" = {
      source = "${claudeCodeSpecSrc}/CLAUDE.md";
    };
    # opencode configuration
    "opencode/AGENTS.md" = {
      source = "${claudeCodeSpecSrc}/CLAUDE.md";
    };
  }
  # add kiro commands to Claude
  // lib.mapAttrs' (name: _: {
    name = "claude/commands/${name}";
    value = {
      source = "${claudeCodeSpecSrc}/.claude/commands/kiro/${name}";
    };
  }) kiroCommands
  # add local ai commands to claude
  // lib.mapAttrs' (name: _: {
    name = "claude/commands/${name}";
    value = {
      source = ./ai/commands + "/${name}";
    };
  }) localAiCommands
  # add kiro commands to opencode instructions
  // lib.mapAttrs' (name: _: {
    name = "opencode/instructions/${name}";
    value = {
      source = "${claudeCodeSpecSrc}/.claude/commands/kiro/${name}";
    };
  }) kiroCommands
  # add local ai commands to opencode instructions
  // lib.mapAttrs' (name: _: {
    name = "opencode/instructions/${name}";
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
