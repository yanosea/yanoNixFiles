{ pkgs, ... }:
{
  # home
  home = {
    packages = with pkgs; [
      wezterm
    ];
  };
}
