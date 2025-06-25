# nixos desktop fonts module
{ pkgs, ... }:
{
  # fonts
  fonts = {
    enableDefaultPackages = true;
    fontDir = {
      enable = true;
    };
    packages = with pkgs; [
      plemoljp-nf
      noto-fonts-emoji
    ];
    fontconfig = {
      enable = true;
    };
  };
}
