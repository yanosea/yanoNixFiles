{ ... }: {
  xdg.configFile."swaync" = {
    source = ./swaync;
    recursive = true;
  };
}
