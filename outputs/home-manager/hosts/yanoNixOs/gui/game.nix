# home game module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      vesktop
      steam
    ];
  };
}
