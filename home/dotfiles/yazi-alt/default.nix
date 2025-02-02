{ ... }: {
  xdg = {
    configFile = {
      "yazi-alt" = {
        source = ./yazi-alt;
        recursive = true;
      };
    };
  };
}
