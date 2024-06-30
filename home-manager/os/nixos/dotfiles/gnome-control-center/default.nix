{ ... }: {
  xdg.configFile."gnome-control-center" = {
    source = ./gnome-control-center;
    recursive = true;
  };
}
