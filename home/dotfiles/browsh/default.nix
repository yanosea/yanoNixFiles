{ ... }: {
  xdg = {
    configFile = {
      "browsh" = {
        source = ./browsh;
        recursive = true;
      };
    };
  };
}
