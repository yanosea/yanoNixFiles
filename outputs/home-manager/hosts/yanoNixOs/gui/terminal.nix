# home terminal module
{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      wezterm
    ];
  };
}
