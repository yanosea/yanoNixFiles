{ pkgs, ... }:
{
  # fonts
  fonts = {
    enableDefaultPackages = true;
    fontDir = {
      enable = true;
    };
    packages = with pkgs; [
      noto-fonts-emoji
      plemoljp-nf
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
