# home lua module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      lua5_4
      luarocks
    ];
  };
}
