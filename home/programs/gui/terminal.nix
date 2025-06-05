{ pkgs, ... }:
{
  imports = [
    ../../dotfiles/wezterm
  ];
  home = {
    packages = with pkgs; [
      wezterm
    ];
  };
}
