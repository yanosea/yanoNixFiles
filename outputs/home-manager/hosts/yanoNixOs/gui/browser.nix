# home browser module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      vivaldi
    ];
  };
}
