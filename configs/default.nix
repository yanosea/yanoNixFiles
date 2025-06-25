# configs (dotfiles)
{ lib, ... }:
let
  contents = builtins.readDir ./.;
  filteredContents = lib.filterAttrs (name: _: name != "default.nix") contents;
  mkEntry = name: type: {
    name = name;
    value = {
      source = ./. + "/${name}";
      recursive = type == "directory";
    };
  };
  configFiles = lib.mapAttrs' mkEntry filteredContents;
in
{
  xdg.configFile = configFiles;
}
