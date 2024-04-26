{ ... }: {
  xdg.configFile."gh" = {
    source = ./gh;
    recursive = true;
  };
}
