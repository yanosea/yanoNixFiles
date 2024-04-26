{ ... }: {
  xdg.configFile."fcitx5" = {
    source = ./fcitx5;
    recursive = true;
  };
}
