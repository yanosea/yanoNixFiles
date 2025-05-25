{ pkgs, ... }:
{
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
      subpixel = {
        lcdfilter = "light";
      };
      defaultFonts = {
        serif = [
          "plemoljp-nf"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
