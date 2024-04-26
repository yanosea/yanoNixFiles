{ ... }: {
  xdg = {
    configFile = {
      "hypr" = {
        source = ./hypr;
        recursive = true;
      };
    };
  };
}
