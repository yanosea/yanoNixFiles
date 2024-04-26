{ ... }: {
  xdg = {
    configFile = {
      "UniGetUI" = {
        source = ./UniGetUI;
        recursive = true;
      };
    };
  };
}
