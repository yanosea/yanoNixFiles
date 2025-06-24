# home java module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [ jdk ];
  };
}
