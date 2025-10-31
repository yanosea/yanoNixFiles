# darwin fonts module
{ pkgs, ... }:
{
  # fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts-color-emoji
      plemoljp-nf
    ];
  };
}
