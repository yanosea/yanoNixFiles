# home nix module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [ nixfmt ];
  };
}
