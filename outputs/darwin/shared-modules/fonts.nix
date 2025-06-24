# darwin fonts module
{ pkgs, ... }:
{
  # fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts-emoji
      plemoljp-nf
    ];
  };
}
