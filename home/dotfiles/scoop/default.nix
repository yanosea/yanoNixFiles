{ ... }: {
  xdg = {
    configFile = {
      "scoop" = {
        source = ./scoop;
        recursive = true;
      };
    };
  };
}
