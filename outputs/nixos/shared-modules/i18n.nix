# nixos i18n module
{ pkgs, ... }:
{
  # i18n
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          fcitx5-mozc
          fcitx5-nord
          fcitx5-skk
        ];
        waylandFrontend = true;
      };
    };
  };
}
