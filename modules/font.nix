{ pkgs, ... }: {
  fonts = {
    fontDir = {
      enable = true;
    };
    packages = with pkgs; [
      plemoljp-nf
      noto-fonts-emoji
    ];
    fontconfig = {
      enable = true;
      subpixel = { lcdfilter = "light"; };
    };
  };
}
