# home browser module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      floorp-bin-unwrapped
      vivaldi
    ];
  };
}
