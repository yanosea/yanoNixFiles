{ ... }: {
  xdg = {
    configFile = {
      "lvim" = {
        source = ./lvim;
        recursive = true;
      };
    };
  };
}
