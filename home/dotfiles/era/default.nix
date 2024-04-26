{ ... }: {
  xdg = {
    configFile = {
      "era" = {
        source = ./era;
        recursive = true;
      };
    };
  };
}
