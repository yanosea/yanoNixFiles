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
      migu
      noto-fonts-color-emoji
      plemoljp-nf
    ];
    fontconfig = {
      enable = true;
    };
  };
}
