{ ... }: {
  xdg = {
    configFile = {
      "zellij" = {
        source = ./zellij;
        recursive = true;
      };
    };
  };
}
