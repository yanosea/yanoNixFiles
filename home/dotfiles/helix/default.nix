{ ... }: {
  xdg = {
    configFile = {
      "helix" = {
        source = ./helix;
        recursive = true;
      };
    };
  };
}
