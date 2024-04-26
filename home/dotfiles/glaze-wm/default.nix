{ ... }: {
  xdg = {
    configFile = {
      "glaze-wm" = {
        source = ./glaze-wm;
        recursive = true;
      };
    };
  };
}
