{ ... }: {
  xdg = {
    configFile = {
      "glzr" = {
        source = ./glzr;
        recursive = true;
      };
    };
  };
}
